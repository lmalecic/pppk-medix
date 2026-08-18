local Batch = require 'mate.batch'
local LineInput = require 'mate.components.line_input'
local input = require 'mate.input'

local EntityController = {}
EntityController.__index = EntityController

local function pressed(msg, ...)
	for index = 1, select('#', ...) do
		if input.pressed(msg, select(index, ...)) then return true end
	end
	return false
end

local function copy(source)
	local result = {}
	for key, value in pairs(source or {}) do result[key] = value end
	return result
end

local function call(repository, method, ...)
	local fn = repository[method]
	if not fn then return nil, 'Repository method ' .. method .. ' is not implemented.' end
	local ok, result, err = pcall(fn, repository, ...)
	if not ok then return nil, tostring(result) end
	return result, err
end

function EntityController.new(view, repository)
	return setmetatable({ view = view, repository = repository }, EntityController)
end

function EntityController:init(scope)
	local searchInput = LineInput.init()
	searchInput.placeholder = self.view.searchPlaceholder or ('Search ' .. self.view.title:lower() .. '...')
	local valueInput = LineInput.init()
	local relationInput = LineInput.init()
	local state = {
		scope = scope,
		lockedValues = copy(scope and scope.lockedValues),
		records = {}, filtered = {}, filter = '', selected = 1,
		focus = 'results', mode = 'view', actionIndex = 1, editIndex = 1,
		draft = nil, searchInput = searchInput, valueInput = valueInput,
		relationInput = relationInput,
		modal = { type = nil, rows = {}, selected = 1, filter = '' },
	}
	local rows, err = call(self.repository, 'list', scope)
	state.records = rows or {}
	self:applyFilter(state)
	return state, Batch(searchInput.msg.enable), err
end

function EntityController:activate(state)
	state.searchInput.enabled, state.valueInput.enabled, state.relationInput.enabled = true, false, false
	return Batch(state.searchInput.msg.enable, state.valueInput.msg.disable, state.relationInput.msg.disable)
end

function EntityController:deactivate(state)
	state.searchInput.enabled, state.valueInput.enabled, state.relationInput.enabled = false, false, false
	return Batch(state.searchInput.msg.disable, state.valueInput.msg.disable, state.relationInput.msg.disable)
end

function EntityController:applyFilter(state)
	local query = (state.filter or ''):lower()
	state.filtered = {}
	for _, entity in ipairs(state.records or {}) do
		local chunks = { self.view:summary(entity) }
		for _, line in ipairs(self.view:detailLines(entity)) do table.insert(chunks, line) end
		if query == '' or table.concat(chunks, ' '):lower():find(query, 1, true) then
			table.insert(state.filtered, entity)
		end
	end
	self:clamp(state)
end

function EntityController:rowCount(state)
	return #state.filtered + (self.view.mutable and 1 or 0)
end

function EntityController:rowAt(state, index)
	if self.view.mutable then
		if index == 1 then return { create = true } end
		return state.filtered[index - 1]
	end
	return state.filtered[index]
end

function EntityController:current(state)
	local row = self:rowAt(state, state.selected)
	if row and not row.create then return row end
	return nil
end

function EntityController:clamp(state)
	local count = self:rowCount(state)
	if count < 1 then state.selected = 1
	elseif state.selected < 1 then state.selected = 1
	elseif state.selected > count then state.selected = count end
end

function EntityController:setInput(state, batch, target)
	state.searchInput.enabled = target == 'search'
	state.valueInput.enabled = target == 'value'
	state.relationInput.enabled = target == 'relation'
	batch.push(state.searchInput.msg.disable)
	batch.push(state.valueInput.msg.disable)
	batch.push(state.relationInput.msg.disable)
	if target == 'search' then batch.push(state.searchInput.msg.enable)
	elseif target == 'value' then batch.push(state.valueInput.msg.enable)
	elseif target == 'relation' then batch.push(state.relationInput.msg.enable) end
end

function EntityController:enterList(state, batch)
	state.focus, state.mode, state.actionIndex = 'results', 'view', 1
	state.draft, state.editIndex = nil, 1
	state.modal.type = nil
	self:setInput(state, batch, 'search')
end

function EntityController:beginEdit(state, create, batch)
	state.focus = 'details'
	state.mode = create and 'create' or 'edit'
	state.editIndex = 1
	state.draft = copy(create and self.view.defaults or self:current(state))
	for key, value in pairs(state.lockedValues) do state.draft[key] = value end
	self:setInput(state, batch, nil)
end

function EntityController:reload(state)
	local rows, err = call(self.repository, 'list', state.scope)
	if not rows then return nil, err end
	state.records = rows
	self:applyFilter(state)
	return true
end

function EntityController:message(kind, text)
	return { type = 'message', message = { kind = kind, title = kind == 'error' and 'Operation failed' or 'Success', text = text } }
end

function EntityController:save(state, batch)
	local method = state.mode == 'create' and 'create' or 'update'
	local entity = state.mode == 'edit' and self:current(state) or nil
	local result, err
	if method == 'create' then result, err = call(self.repository, method, state.draft)
	else result, err = call(self.repository, method, entity, state.draft) end
	if not result then return self:message('error', err or 'The operation was rejected.') end
	local ok, reloadErr = self:reload(state)
	if not ok then return self:message('error', reloadErr) end
	self:enterList(state, batch)
	local verb = method == 'create' and 'created' or 'updated'
	return self:message('success', self.view.title .. ' successfully ' .. verb .. '.')
end

function EntityController:delete(state, batch)
	local entity = self:current(state)
	if not entity then return nil end
	local ok, err = call(self.repository, 'delete', entity)
	if not ok then return self:message('error', err or 'Deletion was rejected.') end
	local loaded, loadErr = self:reload(state)
	if not loaded then return self:message('error', loadErr) end
	self:enterList(state, batch)
	return self:message('success', self.view.title .. ' successfully deleted.')
end

function EntityController:openRelation(state, field, context, batch)
	local rows, err = context:list(field.relation)
	if not rows then return self:message('error', err) end
	state.modal = {
		type = 'relation', field = field, targetView = context:view(field.relation),
		rows = rows, allRows = rows, selected = 1, filter = '',
	}
	state.relationInput.text = ''
	state.relationInput.placeholder = 'Search ' .. state.modal.targetView.title:lower() .. '...'
	state.focus = 'modal'
	self:setInput(state, batch, 'relation')
	return nil
end

function EntityController:openValue(state, field, batch)
	state.modal = { type = 'value', field = field }
	state.valueInput.text = tostring(state.draft[field.key] or '')
	state.focus = 'modal'
	self:setInput(state, batch, 'value')
end

function EntityController:closeModal(state, batch)
	state.focus = 'details'
	state.modal = { type = nil, rows = {}, selected = 1, filter = '' }
	self:setInput(state, batch, nil)
end

function EntityController:performAction(state, action, batch)
	if action.type == 'edit' then self:beginEdit(state, false, batch); return nil end
	if action.type == 'delete' then return self:delete(state, batch) end
	local entity = self:current(state)
	if not entity then return nil end
	if action.type == 'open_entity' then
		return {
			type = 'open_entity', target = action.target,
			scope = { method = action.scopeMethod, id = entity.id, lockedValues = { [action.lockField] = entity.id } },
		}
	elseif action.type == 'manage_prescriptions' then
		return { type = 'manage_prescriptions', history = entity }
	elseif action.type == 'open_prescriptions' then
		return { type = 'open_prescriptions', medication = entity }
	end
	return nil
end

function EntityController:update(state, msg, context)
	local batch, cmd = Batch(), nil
	state.searchInput, cmd = LineInput.update(state.searchInput, msg); batch.push(cmd)
	state.valueInput, cmd = LineInput.update(state.valueInput, msg); batch.push(cmd)
	state.relationInput, cmd = LineInput.update(state.relationInput, msg); batch.push(cmd)

	if state.focus == 'modal' then
		if pressed(msg, 'esc', 'escape') then self:closeModal(state, batch)
		elseif state.modal.type == 'value' and pressed(msg, 'enter', 'return') then
			state.draft[state.modal.field.key] = state.valueInput.text
			self:closeModal(state, batch)
		elseif state.modal.type == 'relation' then
			if pressed(msg, 'up', 'k') then state.modal.selected = math.max(1, state.modal.selected - 1)
			elseif pressed(msg, 'down', 'j') then state.modal.selected = math.min(math.max(1, #state.modal.rows), state.modal.selected + 1)
			elseif pressed(msg, 'enter', 'return') then
				local selected = state.modal.rows[state.modal.selected]
				if selected then state.draft[state.modal.field.key] = selected.id; self:closeModal(state, batch) end
			elseif msg.id == 'line_input:text_changed' and msg.data.uid == state.relationInput.uid then
				state.modal.filter, state.modal.rows, state.modal.selected = msg.data.text, {}, 1
				for _, row in ipairs(state.modal.allRows) do
					if state.modal.targetView:summary(row):lower():find(msg.data.text:lower(), 1, true) then table.insert(state.modal.rows, row) end
				end
			end
		end
		return state, batch
	end

	if pressed(msg, 'esc', 'escape') then
		if state.mode == 'edit' or state.mode == 'create' or state.mode == 'actions' then self:enterList(state, batch)
		else return state, batch, { type = 'close_overlay' } end
	elseif state.mode == 'edit' or state.mode == 'create' then
		local max = #self.view.fields + 2
		if pressed(msg, 'up', 'k') then state.editIndex = math.max(1, state.editIndex - 1)
		elseif pressed(msg, 'down', 'j') then state.editIndex = math.min(max, state.editIndex + 1)
		elseif pressed(msg, 'enter', 'return') then
			if state.editIndex <= #self.view.fields then
				local field = self.view.fields[state.editIndex]
				if state.lockedValues[field.key] == nil and not field.readonly then
					local intent = field.relation and self:openRelation(state, field, context, batch) or self:openValue(state, field, batch)
					if intent then return state, batch, intent end
				end
			elseif state.editIndex == #self.view.fields + 1 then
				return state, batch, self:save(state, batch)
			else self:enterList(state, batch) end
		end
	elseif state.mode == 'actions' then
		local actions = self.view:allActions()
		if pressed(msg, 'up', 'k') then state.actionIndex = math.max(1, state.actionIndex - 1)
		elseif pressed(msg, 'down', 'j') then state.actionIndex = math.min(#actions, state.actionIndex + 1)
		elseif pressed(msg, 'enter', 'return') then return state, batch, self:performAction(state, actions[state.actionIndex], batch) end
	elseif state.focus == 'results' then
		if pressed(msg, 'up', 'k') then state.selected = state.selected - 1; self:clamp(state)
		elseif pressed(msg, 'down', 'j') then state.selected = state.selected + 1; self:clamp(state)
		elseif pressed(msg, 'enter', 'return') then
			local row = self:rowAt(state, state.selected)
			if row and row.create then self:beginEdit(state, true, batch)
			elseif row then state.focus, state.mode, state.actionIndex = 'details', 'actions', 1; self:setInput(state, batch, nil) end
		elseif input.pressed(msg, 'ctrl+l') then
			state.filter = ''; batch.push(state.searchInput.msg.clear); self:applyFilter(state)
		elseif msg.id == 'line_input:text_changed' and msg.data.uid == state.searchInput.uid then
			state.filter, state.selected = msg.data.text, 1; self:applyFilter(state)
		end
	end
	return state, batch
end

return EntityController
