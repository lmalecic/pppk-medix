local LineInput = require 'mate.components.line_input'
local Fieldset = require 'components.fieldset'
local Window = require 'components.window'
local Style = require 'components.style'

local EntityScreen = {}
EntityScreen.__index = EntityScreen

function EntityScreen.new()
	return setmetatable({}, EntityScreen)
end

local function selected_prefix(buf, selected)
	if selected then
		buf:set_fg(Style.colors.selected_cursor)
		buf:set_attr(Style.attributes.strong)
		buf:write(Style.symbols.selection)
	else
		buf:set_fg(Style.colors.muted)
	end
	buf:set_fg(nil)
	buf:set_attr(nil)
end

local function highlighted(buf, text, query, baseColor, baseAttribute)
	text = tostring(text or '')
	query = tostring(query or '')
	if baseColor then buf:set_fg(baseColor) end
	if baseAttribute then buf:set_attr(baseAttribute) end
	if query == '' then buf:write(text); buf:set_fg(nil); buf:set_attr(nil); return end
	local lower, needle, pos = text:lower(), query:lower(), 1
	while true do
		local first, last = lower:find(needle, pos, true)
		if not first then buf:write(text:sub(pos)); break end
		if first > pos then buf:write(text:sub(pos, first - 1)) end
		buf:set_fg(Style.colors.error); buf:set_attr(Style.attributes.strong)
		buf:write(text:sub(first, last))
		buf:set_fg(baseColor); buf:set_attr(baseAttribute)
		pos = last + 1
	end
	buf:set_fg(nil); buf:set_attr(nil)
end

local function draw_search(state, buf)
	buf:set_fg(Style.colors.border); buf:set_attr(Style.attributes.strong); buf:write(Style.symbols.selection)
	buf:set_fg(nil); buf:set_attr(nil)
	LineInput.view(state.searchInput, buf)
end

local function draw_separator(buf, width)
	buf:set_fg(Style.colors.separator)
	buf:write(string.rep(Style.symbols.horizontalDivider, math.max(1, width - 1)))
	buf:set_fg(nil)
end

local function draw_list(controller, state, buf, height)
	local count = controller:rowCount(state)
	if count == 0 then
		buf:set_fg(Style.colors.error); buf:set_attr(Style.attributes.emphasis)
		buf:write('No records found.')
		buf:set_fg(nil); buf:set_attr(nil)
		return
	end
	local maxRows = math.max(1, height)
	local start = math.max(1, state.selected - maxRows + 1)
	if start + maxRows - 1 > count then start = math.max(1, count - maxRows + 1) end
	for screenRow = 0, maxRows - 1 do
		local index = start + screenRow
		local item = controller:rowAt(state, index)
		if item then
			local selected = index == state.selected
			selected_prefix(buf, selected)
			local create = rawget(item, 'create')
			local color = selected and Style.colors.selected or (create and Style.colors.secondary_text or nil)
			if color then buf:set_fg(color) end
			if selected then buf:set_attr(Style.attributes.strong) end
			if create then
				buf:write('+ Create new ' .. controller.view.title:lower())
			else
				highlighted(buf, controller.view:summary(item), state.filter, color, selected and Style.attributes.strong or nil)
			end
			buf:set_fg(nil); buf:set_attr(nil)
			if screenRow < maxRows - 1 then buf:write('\n') end
		end
	end
end

local function draw_fields(controller, state, entity, buf)
	local editing = state.mode == 'edit' or state.mode == 'create'
	local source = editing and state.draft or entity
	for index, field in ipairs(controller.view.fields) do
		local selected = editing and state.editIndex == index
		selected_prefix(buf, selected)
		local labelColor = editing and not selected and Style.colors.secondary_text or Style.colors.accent
		buf:set_fg(labelColor); buf:set_attr(Style.attributes.strong); buf:write(field.label .. ': ')
		buf:set_fg(nil); buf:set_attr(nil)
		local value = controller.view:fieldValue(source, field, editing and state.draftRelations[field.key] or nil)
		if editing and value == '' then
			local placeholder = controller.view:placeholder(field)
			if placeholder then
				buf:set_fg(Style.colors.secondary_text); buf:set_attr(Style.attributes.emphasis)
				buf:write(placeholder); buf:set_fg(nil); buf:set_attr(nil)
			end
		else buf:write(value) end
		if state.lockedValues[field.key] ~= nil then
			buf:set_fg(Style.colors.muted); buf:write('  (fixed)'); buf:set_fg(nil)
		elseif selected and (field.relation or field.dateTime) then
			buf:set_fg(Style.colors.muted); buf:write(field.dateTime and '  ENTER pick date/time' or '  ENTER select'); buf:set_fg(nil)
		end
		buf:write('\n')
	end
end

local function draw_actions(controller, state, buf)
	local actions = controller.view:allActions()
	for index, action in ipairs(actions) do
		selected_prefix(buf, state.mode == 'actions' and state.actionIndex == index)
		buf:write(action.label)
		buf:write('\n')
	end
	buf:write('\n')
	buf:set_fg(Style.colors.muted)
	buf:write(state.mode == 'actions' and 'UP/DOWN select, ENTER confirm, ESC back' or 'ENTER for actions')
	buf:set_fg(nil)
end

local function draw_editor_actions(controller, state, buf)
	local labels = state.mode == 'create' and { 'Create', 'Cancel' } or { 'Save', 'Cancel' }
	for index, label in ipairs(labels) do
		local absolute = #controller.view.fields + index
		selected_prefix(buf, state.editIndex == absolute)
		buf:write(label)
		if index < #labels then buf:write('\n') end
	end
	buf:write('\n\n')
	buf:set_fg(Style.colors.muted); buf:write('UP/DOWN select, ENTER change, ESC cancel'); buf:set_fg(nil)
end

local function draw_details(controller, state, buf)
	local entity = controller:current(state)
	if not entity and state.mode ~= 'create' then
		buf:set_fg(Style.colors.accent); buf:write('Select a record to view its details.'); buf:set_fg(nil)
		return
	end
	draw_fields(controller, state, entity, buf)
	if state.mode == 'edit' or state.mode == 'create' then
		buf:write('\n')
		draw_editor_actions(controller, state, buf)
		return
	end
	local detailLines = controller.view:detailLines(entity)
	if #detailLines > 0 then
		buf:write('\n')
		for _, line in ipairs(detailLines) do buf:write(line .. '\n') end
	end
	buf:write('\n')
	draw_actions(controller, state, buf)
end

local function draw_relation_modal(controller, state, buf, layout)
	if state.modal.type ~= 'relation' then return end
	buf:with_offset(layout.modal.x, layout.modal.y, function()
		Window.title(layout.modal.window, 'Select ' .. state.modal.targetView.title)
		Window.draw(layout.modal.window, buf, layout.modal.resolved, function(width, height)
			buf:set_fg(Style.colors.border); buf:set_attr(Style.attributes.strong); buf:write(Style.symbols.selection)
			buf:set_fg(nil); buf:set_attr(nil)
			LineInput.view(state.relationInput, buf)
			buf:write('\n'); draw_separator(buf, width); buf:write('\n')
			local rows = state.modal.rows
			if #rows == 0 then buf:write('No records found.'); return end
			local maxRows = math.max(1, height - 4)
			local start = math.max(1, state.modal.selected - maxRows + 1)
			for i = 0, maxRows - 1 do
				local row = rows[start + i]
				if row then
					local selected = start + i == state.modal.selected
					selected_prefix(buf, selected)
					highlighted(buf, state.modal.targetView:summary(row), state.modal.filter,
						selected and Style.colors.selected or nil, selected and Style.attributes.strong or nil)
					if i < maxRows - 1 then buf:write('\n') end
				end
			end
		end)
	end)
end

local function draw_date_modal(state, buf, layout)
	if state.modal.type ~= 'date' then return end
	buf:with_offset(layout.input.x, layout.input.y, function()
		Window.title(layout.input.window, state.modal.field.label)
		Window.draw(layout.input.window, buf, layout.input.resolved, function()
			state.modal.picker:view(buf)
			buf:write('\n')
			buf:set_fg(Style.colors.muted)
			buf:write('Type digits or use UP/DOWN; LEFT/RIGHT part, ENTER confirm, ESC cancel')
			buf:set_fg(nil)
		end)
	end)
end

local function draw_value_modal(state, buf, layout)
	if state.modal.type ~= 'value' then return end
	buf:with_offset(layout.input.x, layout.input.y, function()
		Window.title(layout.input.window, state.modal.field.label)
		Window.draw(layout.input.window, buf, layout.input.resolved, function(width)
			buf:set_fg(Style.colors.border); buf:set_attr(Style.attributes.strong); buf:write(Style.symbols.selection)
			buf:set_fg(nil); buf:set_attr(nil)
			LineInput.view(state.valueInput, buf)
			buf:write('\n')
			buf:set_fg(Style.colors.muted); buf:write('ENTER confirm, ESC cancel'); buf:set_fg(nil)
		end)
	end)
end

function EntityScreen:view(controller, state, buf, layout, overlay)
	if overlay then
		buf:with_offset(layout.overlay.x, layout.overlay.y, function()
			Window.title(layout.overlay.window, controller.view.title)
			Window.draw(layout.overlay.window, buf, layout.overlay.resolved, function(width, height)
				local leftWidth = math.max(20, math.floor(width * 0.48))
				buf:with_offset(0, 0, function()
					buf:with_clip(0, 0, leftWidth, height, function()
						draw_search(state, buf)
						buf:write('\n'); draw_separator(buf, leftWidth); buf:write('\n')
						draw_list(controller, state, buf, math.max(1, height - 3))
					end)
				end)
				buf:with_offset(leftWidth, 0, function()
					buf:set_fg(Style.colors.border)
					for row = 0, height - 1 do buf:move_to(0, row); buf:write(Style.symbols.verticalDivider) end
					buf:set_fg(nil)
				end)
				buf:with_offset(leftWidth + 2, 0, function()
					buf:with_clip(0, 0, math.max(1, width - leftWidth - 2), height, function()
						draw_details(controller, state, buf)
					end)
				end)
			end)
		end)
	else
		buf:with_offset(layout.search.x, layout.search.y, function()
			Fieldset.draw(layout.search.fieldset, buf, layout.search.resolved, function() draw_search(state, buf) end)
		end)
		buf:with_offset(layout.list.x, layout.list.y, function()
			Fieldset.draw(layout.list.fieldset, buf, layout.list.resolved, function(_, height) draw_list(controller, state, buf, height) end)
		end)
		buf:with_offset(layout.details.x, layout.details.y, function()
			Fieldset.title(layout.details.fieldset, controller.view.title)
			Fieldset.draw(layout.details.fieldset, buf, layout.details.resolved, function() draw_details(controller, state, buf) end)
		end)
	end
	draw_relation_modal(controller, state, buf, layout)
	draw_value_modal(state, buf, layout)
	draw_date_modal(state, buf, layout)
end

return EntityScreen
