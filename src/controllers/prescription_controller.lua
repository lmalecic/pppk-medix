local Batch = require 'mate.batch'
local LineInput = require 'mate.components.line_input'
local input = require 'mate.input'

local PrescriptionController = {}
PrescriptionController.__index = PrescriptionController

local function pressed(msg, ...)
	for i = 1, select('#', ...) do if input.pressed(msg, select(i, ...)) then return true end end
	return false
end

local function safe(repository, method, ...)
	local ok, value, err = pcall(repository[method], repository, ...)
	if not ok then return nil, tostring(value) end
	return value, err
end

local function medicationOf(prescription)
	local ok, medication = pcall(function() return prescription.medication end)
	if ok and medication then return medication end
	return prescription
end

function PrescriptionController.new(repository)
	return setmetatable({ repository = repository, kind = 'prescriptions' }, PrescriptionController)
end

function PrescriptionController:init(scope)
	local search = LineInput.init(); search.placeholder = 'Search prescriptions...'
	local pickerSearch = LineInput.init(); pickerSearch.placeholder = 'Search medications...'
	local rows, err
	if scope.history then rows, err = safe(self.repository, 'listByHistory', scope.history.id)
	else rows, err = safe(self.repository, 'listByMedication', scope.medication.id) end
	local state = {
		scope = scope, rows = rows or {}, filtered = rows or {}, selected = 1,
		filter = '', searchInput = search, pickerInput = pickerSearch,
		mode = 'list', pickerRows = {}, pickerAllRows = {}, pickerSelected = 1,
	}
	return state, Batch(search.msg.enable), err
end

function PrescriptionController:deactivate(state)
	state.searchInput.enabled, state.pickerInput.enabled = false, false
	return Batch(state.searchInput.msg.disable, state.pickerInput.msg.disable)
end

function PrescriptionController:activate(state)
	state.searchInput.enabled, state.pickerInput.enabled = true, false
	return Batch(state.searchInput.msg.enable, state.pickerInput.msg.disable)
end

function PrescriptionController:rowCount(state)
	return #state.filtered + (state.scope.history and 1 or 0)
end

function PrescriptionController:rowAt(state, index)
	if state.scope.history then
		if index == 1 then return { prescribe = true } end
		return state.filtered[index - 1]
	end
	return state.filtered[index]
end

function PrescriptionController:label(row)
	local medication = medicationOf(row)
	return tostring(medication.name or ('Medication #' .. tostring(row.medication_id or '?')))
		.. ' | ' .. tostring(medication.dosage or '-') .. ' | ' .. tostring(medication.frequency or '-')
end

function PrescriptionController:clamp(state)
	local count = self:rowCount(state)
	if count < 1 then state.selected = 1 else state.selected = math.max(1, math.min(count, state.selected)) end
end

function PrescriptionController:filter(state)
	state.filtered = {}
	local query = state.filter:lower()
	for _, row in ipairs(state.rows) do
		if self:label(row):lower():find(query, 1, true) then table.insert(state.filtered, row) end
	end
	self:clamp(state)
end

function PrescriptionController:reload(state)
	local rows, err
	if state.scope.history then rows, err = safe(self.repository, 'listByHistory', state.scope.history.id)
	else rows, err = safe(self.repository, 'listByMedication', state.scope.medication.id) end
	if not rows then return nil, err end
	state.rows = rows; self:filter(state); return true
end

function PrescriptionController:message(kind, text)
	return { type = 'message', message = { kind = kind, title = kind == 'error' and 'Operation failed' or 'Success', text = text } }
end

function PrescriptionController:openPicker(state, context, batch)
	local rows, err = context:list('medications')
	if not rows then return self:message('error', err) end
	state.mode, state.pickerAllRows, state.pickerRows, state.pickerSelected = 'picker', rows, rows, 1
	state.pickerInput.text = ''
	state.searchInput.enabled, state.pickerInput.enabled = false, true
	batch.push(state.searchInput.msg.disable); batch.push(state.pickerInput.msg.enable)
end

function PrescriptionController:update(state, msg, context)
	local batch, cmd = Batch(), nil
	state.searchInput, cmd = LineInput.update(state.searchInput, msg); batch.push(cmd)
	state.pickerInput, cmd = LineInput.update(state.pickerInput, msg); batch.push(cmd)
	if state.mode == 'picker' then
		if pressed(msg, 'esc', 'escape') then
			state.mode = 'list'; state.pickerInput.enabled, state.searchInput.enabled = false, true
			batch.push(state.pickerInput.msg.disable); batch.push(state.searchInput.msg.enable)
		elseif pressed(msg, 'up', 'k') then state.pickerSelected = math.max(1, state.pickerSelected - 1)
		elseif pressed(msg, 'down', 'j') then state.pickerSelected = math.min(math.max(1, #state.pickerRows), state.pickerSelected + 1)
		elseif pressed(msg, 'enter', 'return') then
			local medication = state.pickerRows[state.pickerSelected]
			if medication then
				local result, err = safe(self.repository, 'prescribe', state.scope.history.id, medication)
				if not result then return state, batch, self:message('error', err or 'Prescription was rejected.') end
				self:reload(state); state.mode = 'list'; state.pickerInput.enabled, state.searchInput.enabled = false, true
				batch.push(state.pickerInput.msg.disable); batch.push(state.searchInput.msg.enable)
				return state, batch, self:message('success', 'Medication successfully prescribed.')
			end
		elseif msg.id == 'line_input:text_changed' and msg.data.uid == state.pickerInput.uid then
			state.pickerRows, state.pickerSelected = {}, 1
			for _, medication in ipairs(state.pickerAllRows) do
				local view = context:view('medications')
				if view:summary(medication):lower():find(msg.data.text:lower(), 1, true) then table.insert(state.pickerRows, medication) end
			end
		end
		return state, batch
	end
	if pressed(msg, 'esc', 'escape') then return state, batch, { type = 'close_overlay' }
	elseif pressed(msg, 'up', 'k') then state.selected = state.selected - 1; self:clamp(state)
	elseif pressed(msg, 'down', 'j') then state.selected = state.selected + 1; self:clamp(state)
	elseif pressed(msg, 'enter', 'return') then
		local row = self:rowAt(state, state.selected)
		if row and rawget(row, 'prescribe') then
			local intent = self:openPicker(state, context, batch)
			if intent then return state, batch, intent end
		elseif row and state.scope.history then
			local ok, err = safe(self.repository, 'remove', row)
			if not ok then return state, batch, self:message('error', err or 'Removal was rejected.') end
			self:reload(state)
			return state, batch, self:message('success', 'Prescription successfully removed.')
		end
	elseif input.pressed(msg, 'ctrl+l') then
		state.filter = ''; batch.push(state.searchInput.msg.clear); self:filter(state)
	elseif msg.id == 'line_input:text_changed' and msg.data.uid == state.searchInput.uid then
		state.filter = msg.data.text; state.selected = 1; self:filter(state)
	end
	return state, batch
end

return PrescriptionController
