local App = require 'mate.app'
local Batch = require 'mate.batch'
local LineInput = require 'mate.components.line_input'
local input = require 'mate.input'

local Store = require 'store'
local Fieldset = require 'components.fieldset'
local Header = require 'components.header'
local SearchBox = require 'components.search_box'
local RecordList = require 'components.record_list'
local DetailPanel = require 'components.detail_panel'

local ACTIONS = { 'Add', 'Edit', 'Delete' }

local function pressed_any(msg, keys)
	for _, key in ipairs(keys) do
		if input.pressed(msg, key) then return true end
	end
	return false
end

local function clamp_selection(model)
	local count = #Store.filtered_rows(model)
	if count == 0 then
		model.selected = 1
	elseif model.selected < 1 then
		model.selected = 1
	elseif model.selected > count then
		model.selected = count
	end
end

local function switch_entity(model, direction)
	local next_entity = model.entity + direction
	if next_entity < 1 or next_entity > #Store.schemas then return end

	model.entity = next_entity
	model.selected = 1
	model.focus = 'list'
	model.action_index = 1
	model.message = 'Prikaz: ' .. Store.selected_schema(model).title
end

local function current_item(model)
	local visible = Store.filtered_rows(model)
	return visible[model.selected], visible
end

local function first_editable_field(schema)
	for _, field in ipairs(schema.fields) do
		return field
	end
	return nil
end

local function perform_action(model, schema, batch)
	if not schema.mutable then return end

	local item = current_item(model)
	local rows = Store.db[schema.key]
	local action = ACTIONS[model.action_index]

	if action == 'Add' then
		local row = Store.create_row(schema, {})
		model.filter = ''
		batch.push(model.search_input.msg.clear)
		model.selected = #rows
		model.message = 'Dodano: ' .. schema.summary(row)
	elseif action == 'Edit' then
		if not item then return end

		local field = first_editable_field(schema)
		if field then
			Store.update_row(schema, item.row, {
				[field] = tostring(item.row[field] or '') .. ' (azurirano)',
			})
			model.message = 'Azurirano: ' .. schema.summary(item.row)
		end
	elseif action == 'Delete' then
		if not item then return end

		local deleted = table.remove(rows, item.index)
		model.focus = 'list'
		model.action_index = 1
		clamp_selection(model)
		model.message = 'Obrisano: ' .. schema.summary(deleted)
	end
end

local function layout(model, w, h)
	model.size = { w, h }

	model.header_pos = { 1, 1 }
	Fieldset.width(model.header_fieldset, math.max(24, w - 1))
	Fieldset.height(model.header_fieldset, 3)
	model.header_layout = Fieldset.resolve(model.header_fieldset)

	local left_width = math.max(24, math.floor((w - 2) * 0.52))

	model.search_pos = { 1, 4 }
	Fieldset.width(model.search_fieldset, left_width)
	Fieldset.height(model.search_fieldset, 3)
	model.search_layout = Fieldset.resolve(model.search_fieldset)

	model.list_pos = { 1, 7 }
	Fieldset.width(model.list_fieldset, left_width)
	Fieldset.height(model.list_fieldset, math.max(5, h - 7))
	model.list_layout = Fieldset.resolve(model.list_fieldset)

	model.detail_pos = { model.list_layout.total_w + 2, 4 }
	Fieldset.width(model.detail_fieldset, math.max(24, w - model.list_layout.total_w - 2))
	Fieldset.height(model.detail_fieldset, math.max(5, h - 4))
	model.detail_layout = Fieldset.resolve(model.detail_fieldset)
end

local function create_model(batch)
	local search_input = LineInput.init()
	search_input.placeholder = 'Ime, OIB, lijek, termin...'
	batch.push(search_input.msg.enable)

	return {
		ready = false,
		size = { 0, 0 },
		entity = 1,
		selected = 1,
		focus = 'list',
		action_index = 1,
		filter = '',
		message = 'Medicinski sustav koristi mock podatke; ORM i baza dolaze kasnije.',
		search_input = search_input,
		header_fieldset = Fieldset.init('Medicinski sustav v0.1'),
		search_fieldset = Fieldset.init('Search'),
		list_fieldset = Fieldset.init('Results'),
		detail_fieldset = Fieldset.init(''),
	}
end

App {
	config = {
		fps = 30,
		log_key = 'f12',
		term_poll_timeout = 10,
	},

	init = function()
		local batch = Batch()
		return create_model(batch), batch
	end,

	update = function(model, msg, cmd)
		local batch = Batch()

		model.search_input, cmd = LineInput.update(model.search_input, msg)
		batch.push(cmd)

		if msg.id == 'sys:ready' then
			model.ready = true
			layout(model, msg.data.width, msg.data.height)
		elseif msg.id == 'sys:resize' then
			layout(model, msg.data.width, msg.data.height)
		elseif input.pressed(msg, 'ctrl+c') then
			batch.push({ id = 'quit' })
		elseif pressed_any(msg, { 'esc', 'escape' }) then
			model.focus = 'list'
			model.action_index = 1
		elseif (input.pressed(msg, 'up') or input.pressed(msg, 'k')) and model.focus == 'detail' then
			model.action_index = model.action_index - 1
			if model.action_index < 1 then model.action_index = 1 end
		elseif (input.pressed(msg, 'down') or input.pressed(msg, 'j')) and model.focus == 'detail' then
			model.action_index = model.action_index + 1
			if model.action_index > #ACTIONS then model.action_index = #ACTIONS end
		elseif pressed_any(msg, { 'enter', 'return' }) and model.focus == 'detail' then
			perform_action(model, Store.selected_schema(model), batch)
		elseif pressed_any(msg, { 'enter', 'return' }) then
			local schema = Store.selected_schema(model)
			local item = current_item(model)
			if item and schema.mutable then
				model.focus = 'detail'
				model.action_index = 1
			end
		elseif input.pressed(msg, 'left') then
			switch_entity(model, -1)
		elseif input.pressed(msg, 'right') then
			switch_entity(model, 1)
		elseif (input.pressed(msg, 'up') or input.pressed(msg, 'k')) and model.focus == 'list' then
			model.selected = model.selected - 1
			clamp_selection(model)
		elseif (input.pressed(msg, 'down') or input.pressed(msg, 'j')) and model.focus == 'list' then
			model.selected = model.selected + 1
			clamp_selection(model)
		elseif input.pressed(msg, 'ctrl+l') then
			model.filter = ''
			batch.push(model.search_input.msg.clear)
			model.message = 'Filter je ociscen.'
		elseif msg.id == 'line_input:text_changed' and msg.data.uid == model.search_input.uid then
			model.filter = msg.data.text
			model.selected = 1
			model.focus = 'list'
			model.action_index = 1
			clamp_selection(model)
		end

		return model, batch
	end,

	view = function(model, buf)
		if not model.ready then return end

		local schema = Store.selected_schema(model)
		local visible = Store.filtered_rows(model)
		local current = visible[model.selected]

		Header.view(model, buf, schema, Store.db, Store.schemas)
		SearchBox.view(model, buf)
		RecordList.view(model, buf, schema, visible)
		DetailPanel.view(model, buf, schema, current, ACTIONS)
	end
}
