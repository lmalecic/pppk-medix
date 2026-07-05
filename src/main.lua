local Orm = require("lua-orm")

local App = require 'mate.app'
local Batch = require 'mate.batch'
local LineInput = require 'mate.components.line_input'
local input = require 'mate.input'

local Store = require 'store'
local Fieldset = require 'components.fieldset'
local Window = require 'components.window'
local Header = require 'components.header'
local SearchBox = require 'components.search_box'
local RecordList = require 'components.record_list'
local DetailPanel = require 'components.detail_panel'
local RelationModal = require 'components.relation_modal'
local InputDialog = require 'components.input_dialog'

local ACTIONS = { 'Edit', 'Delete' }
local EDIT_ACTIONS = { 'Save', 'Cancel' }
local CREATE_ACTIONS = { 'Create', 'Cancel' }

local function sync_legacy_state(model)
	model.selected = model.results.selected
	model.filter = model.results.filter
	model.action_index = model.details.action_index
	model.edit_index = model.details.edit_index
	model.edit_draft = model.details.draft
	model.relation_filter = model.modal.relation_filter
	model.relation_selected = model.modal.relation_selected
	model.relation_current_id = model.modal.relation_current_id
end

local function pressed_any(msg, keys)
	for _, key in ipairs(keys) do
		if input.pressed(msg, key) then return true end
	end
	return false
end

local clear_edit_state

local function details_is_editing(model)
	return model.details.mode == 'edit' or model.details.mode == 'create'
end

local function clamp_selection(model)
	local schema = Store.selected_schema(model)
	local visible_count = #Store.filtered_rows(model)
	local count = schema.mutable and (visible_count + 1) or visible_count

	if count == 0 then
		model.results.selected = 1
	elseif model.results.selected < 1 then
		model.results.selected = 1
	elseif model.results.selected > count then
		model.results.selected = count
	end
	sync_legacy_state(model)
end

local function switch_entity(model, direction)
	local next_entity = model.entity + direction
	if next_entity < 1 or next_entity > #Store.schemas then return end

	model.entity = next_entity
	model.focus = 'results'
	model.results.selected = 1
	model.details.mode = 'view'
	model.details.action_index = 1
	clear_edit_state(model)
	model.message = 'Prikaz: ' .. Store.selected_schema(model).title
	sync_legacy_state(model)
end

local function current_item(model)
	local visible = Store.filtered_rows(model)
	local schema = Store.selected_schema(model)
	if schema.mutable and model.results.selected == 1 then
		return nil, visible
	end

	local offset = schema.mutable and 1 or 0
	return visible[model.results.selected - offset], visible
end

local function select_row_by_id(model, row_id)
	local visible = Store.filtered_rows(model)
	for i, item in ipairs(visible) do
		if tostring(item.row.id) == tostring(row_id) then
			model.results.selected = i + (Store.selected_schema(model).mutable and 1 or 0)
			sync_legacy_state(model)
			return true
		end
	end
	return false
end

local function set_input_mode(model, batch, mode)
	batch.push(model.search_input.msg.disable)
	batch.push(model.value_input.msg.disable)
	batch.push(model.relation_search_input.msg.disable)

	if mode == 'search' then
		batch.push(model.search_input.msg.enable)
	elseif mode == 'value' then
		batch.push(model.value_input.msg.enable)
	elseif mode == 'relation' then
		batch.push(model.relation_search_input.msg.enable)
	end
end

local function selected_field(schema, model)
	return schema.fields[model.details.edit_index]
end

function clear_edit_state(model)
	model.details.draft = nil
	model.details.edit_source_index = nil
	model.details.edit_index = 1
	model.modal.value_field = nil
	model.modal.relation_field = nil
	model.modal.relation_filter = ''
	model.modal.relation_selected = 1
	model.modal.relation_current_id = nil
	sync_legacy_state(model)
end

local function copy_row_fields(schema, row)
	local draft = { id = row.id }
	for _, field in ipairs(schema.fields) do
		draft[field] = row[field]
	end
	return draft
end

local function copy_defaults(schema)
	local draft = {}
	for _, field in ipairs(schema.fields) do
		draft[field] = schema.defaults[field]
	end
	return draft
end

local function enter_list(model, batch)
	model.focus = 'results'
	model.details.mode = 'view'
	model.details.action_index = 1
	clear_edit_state(model)
	set_input_mode(model, batch, 'search')
end

local function enter_detail(model, batch)
	model.focus = 'details'
	model.details.mode = 'actions'
	model.details.action_index = 1
	clear_edit_state(model)
	set_input_mode(model, batch, nil)
end

local function enter_field_edit(model, schema, row, batch)
	model.focus = 'details'
	model.details.mode = 'edit'
	model.details.edit_index = 1
	model.details.draft = copy_row_fields(schema, row)
	sync_legacy_state(model)
	set_input_mode(model, batch, nil)
end

local function enter_create(model, schema, batch)
	model.focus = 'details'
	model.details.mode = 'create'
	model.details.edit_index = 1
	model.details.draft = copy_defaults(schema)
	sync_legacy_state(model)
	set_input_mode(model, batch, nil)
end

local function relation_rows(model)
	return Store.related_rows(model.modal.relation_field, model.modal.relation_filter)
end

local function clamp_relation_selection(model)
	local count = #relation_rows(model)
	if count == 0 then
		model.modal.relation_selected = 1
	elseif model.modal.relation_selected < 1 then
		model.modal.relation_selected = 1
	elseif model.modal.relation_selected > count then
		model.modal.relation_selected = count
	end
	sync_legacy_state(model)
end

local function open_relation_modal(model, schema, batch)
	local field = selected_field(schema, model)
	local relation = Store.relation_for(field)
	if not relation then return end

	local target_schema = Store.schema_by_key[relation.schema_key]
	model.focus = 'modal'
	model.modal.type = 'relation'
	model.modal.relation_field = field
	model.modal.relation_filter = ''
	model.modal.relation_selected = 1
	model.modal.relation_current_id = model.details.draft[field]
	model.relation_search_input.text = ''
	model.relation_search_input.placeholder = 'Search ' .. target_schema.title:lower() .. '...'
	Window.title(model.relation_window, target_schema.title)
	set_input_mode(model, batch, 'relation')
	clamp_relation_selection(model)
end

local function return_to_field_edit(model, batch)
	model.focus = 'details'
	model.modal.type = nil
	sync_legacy_state(model)
	set_input_mode(model, batch, nil)
end

local function open_value_dialog(model, schema, batch)
	local field = selected_field(schema, model)
	if not field or Store.relation_for(field) then return end

	model.focus = 'modal'
	model.modal.type = 'value'
	model.modal.value_field = field
	model.value_input.text = tostring(model.details.draft[field] or '')
	model.value_input.placeholder = tostring(model.details.draft[field] or '')
	Window.title(model.value_window, field)
	set_input_mode(model, batch, 'value')
end

local function confirm_value_dialog(model, batch)
	if model.modal.value_field then
		model.details.draft[model.modal.value_field] = model.value_input.text
	end
	return_to_field_edit(model, batch)
end

local function save_edit(model, schema, batch)
	local item = current_item(model)
	if not item or not model.details.draft then return end

	local assignments = {}
	for _, field in ipairs(schema.fields) do
		assignments[field] = model.details.draft[field]
	end
	Store.update_row(schema, item.row, assignments)
	if not select_row_by_id(model, item.row.id) then
		model.results.filter = ''
		batch.push(model.search_input.msg.clear)
		sync_legacy_state(model)
		select_row_by_id(model, item.row.id)
	end
	model.message = 'Spremljeno: ' .. schema.summary(item.row)
	enter_list(model, batch)
end

local function create_draft(model, schema, batch)
	if not model.details.draft then return end

	local row = Store.create_row(schema, model.details.draft)
	if model.results.filter ~= '' then
		model.results.filter = ''
		batch.push(model.search_input.msg.clear)
	end
	select_row_by_id(model, row.id)
	model.message = 'Dodano: ' .. schema.summary(row)
	enter_list(model, batch)
end

local function cancel_edit(model, batch)
	model.message = 'Promjene su odbacene.'
	enter_list(model, batch)
end

local function edit_item_count(model, schema)
	local actions = model.details.mode == 'create' and CREATE_ACTIONS or EDIT_ACTIONS
	return #schema.fields + #actions
end

local function clamp_edit_index(model, schema)
	if model.details.edit_index < 1 then
		model.details.edit_index = 1
	elseif model.details.edit_index > edit_item_count(model, schema) then
		model.details.edit_index = edit_item_count(model, schema)
	end
	sync_legacy_state(model)
end

local function selected_edit_action(schema, model)
	local action_index = model.details.edit_index - #schema.fields
	if action_index < 1 then return nil end
	local actions = model.details.mode == 'create' and CREATE_ACTIONS or EDIT_ACTIONS
	return actions[action_index]
end

local function activate_edit_selection(model, schema, batch)
	local action = selected_edit_action(schema, model)
	if action == 'Create' then
		create_draft(model, schema, batch)
	elseif action == 'Save' then
		save_edit(model, schema, batch)
	elseif action == 'Cancel' then
		cancel_edit(model, batch)
	else
		local field = selected_field(schema, model)
		if Store.relation_for(field) then
			open_relation_modal(model, schema, batch)
		else
			open_value_dialog(model, schema, batch)
		end
	end
end

local function perform_action(model, schema, batch)
	if not schema.mutable then return end

	local item = current_item(model)
	local rows = Store.db[schema.key]
	local action = ACTIONS[model.details.action_index]

	if action == 'Edit' then
		if not item then return end
		model.details.edit_source_index = item.index
		enter_field_edit(model, schema, item.row, batch)
	elseif action == 'Delete' then
		if not item then return end

		local deleted = table.remove(rows, item.index)
		enter_list(model, batch)
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

	local modal_w = math.min(math.max(36, math.floor(w * 0.55)), math.max(36, w - 8))
	local modal_h = math.min(math.max(12, math.floor(h * 0.55)), math.max(12, h - 6))
	local modal_x = math.max(1, math.floor((w - modal_w) / 2))
	local modal_y = math.max(2, math.floor((h - modal_h) / 2))

	model.relation_window_pos = { modal_x, modal_y }
	Window.width(model.relation_window, modal_w)
	Window.height(model.relation_window, modal_h)
	model.relation_window_layout = Window.resolve(model.relation_window)

	local input_w = math.min(math.max(34, math.floor(w * 0.45)), math.max(34, w - 10))
	local input_h = 4
	model.value_dialog_pos = {
		math.max(1, math.floor((w - input_w) / 2)),
		math.max(2, math.floor((h - input_h) / 2)),
	}
	Window.width(model.value_window, input_w)
	Window.height(model.value_window, input_h)
	model.value_window_layout = Window.resolve(model.value_window)
end

local function create_model(batch)
	local search_input = LineInput.init()
	search_input.placeholder = 'Name, OIB, Medication, Appointment...'
	batch.push(search_input.msg.enable)

	local value_input = LineInput.init()
	local relation_search_input = LineInput.init()

	return {
		ready = false,
		size = { 0, 0 },
		entity = 1,
		focus = 'results',
		results = {
			selected = 1,
			filter = '',
		},
		details = {
			mode = 'view',
			action_index = 1,
			edit_index = 1,
			draft = nil,
			edit_source_index = nil,
		},
		modal = {
			type = nil,
			value_field = nil,
			relation_field = nil,
			relation_filter = '',
			relation_selected = 1,
			relation_current_id = nil,
		},
		selected = 1,
		action_index = 1,
		edit_index = 1,
		filter = '',
		edit_draft = nil,
		relation_filter = '',
		relation_selected = 1,
		relation_current_id = nil,
		message = '',
		search_input = search_input,
		value_input = value_input,
		relation_search_input = relation_search_input,
		header_fieldset = Fieldset.init('MediX v0.1'),
		search_fieldset = Fieldset.init('Search'),
		list_fieldset = Fieldset.init('Results'),
		detail_fieldset = Fieldset.init(''),
		relation_window = Window.init(''),
		value_window = Window.init('Input value'),
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
		model.value_input, cmd = LineInput.update(model.value_input, msg)
		batch.push(cmd)
		model.relation_search_input, cmd = LineInput.update(model.relation_search_input, msg)
		batch.push(cmd)

		local schema = Store.selected_schema(model)
		local item = current_item(model)

		if msg.id == 'sys:ready' then
			model.ready = true
			layout(model, msg.data.width, msg.data.height)
		elseif msg.id == 'sys:resize' then
			layout(model, msg.data.width, msg.data.height)
		elseif input.pressed(msg, 'ctrl+c') then
			batch.push({ id = 'quit' })
		elseif pressed_any(msg, { 'esc', 'escape' }) then
			if model.focus == 'modal' then
				return_to_field_edit(model, batch)
			elseif model.focus == 'details' and details_is_editing(model) then
				cancel_edit(model, batch)
			else
				enter_list(model, batch)
			end
		elseif (input.pressed(msg, 'up') or input.pressed(msg, 'k')) and model.focus == 'modal' and model.modal.type == 'relation' then
			model.modal.relation_selected = model.modal.relation_selected - 1
			clamp_relation_selection(model)
		elseif (input.pressed(msg, 'down') or input.pressed(msg, 'j')) and model.focus == 'modal' and model.modal.type == 'relation' then
			model.modal.relation_selected = model.modal.relation_selected + 1
			clamp_relation_selection(model)
		elseif pressed_any(msg, { 'enter', 'return' }) and model.focus == 'modal' and model.modal.type == 'relation' then
			local rows = relation_rows(model)
			local selected = rows[model.modal.relation_selected]
			if selected and item then
				model.details.draft[model.modal.relation_field] = selected.row.id
				model.modal.relation_current_id = selected.row.id
				model.message = 'Odabrano: ' .. selected.label
				return_to_field_edit(model, batch)
			end
		elseif (input.pressed(msg, 'up') or input.pressed(msg, 'k')) and model.focus == 'details' and details_is_editing(model) then
			model.details.edit_index = model.details.edit_index - 1
			clamp_edit_index(model, schema)
		elseif (input.pressed(msg, 'down') or input.pressed(msg, 'j')) and model.focus == 'details' and details_is_editing(model) then
			model.details.edit_index = model.details.edit_index + 1
			clamp_edit_index(model, schema)
		elseif pressed_any(msg, { 'enter', 'return' }) and model.focus == 'details' and details_is_editing(model) then
			activate_edit_selection(model, schema, batch)
		elseif pressed_any(msg, { 'enter', 'return' }) and model.focus == 'modal' and model.modal.type == 'value' then
			confirm_value_dialog(model, batch)
		elseif (input.pressed(msg, 'up') or input.pressed(msg, 'k')) and model.focus == 'details' and model.details.mode == 'actions' then
			model.details.action_index = model.details.action_index - 1
			if model.details.action_index < 1 then model.details.action_index = 1 end
			sync_legacy_state(model)
		elseif (input.pressed(msg, 'down') or input.pressed(msg, 'j')) and model.focus == 'details' and model.details.mode == 'actions' then
			model.details.action_index = model.details.action_index + 1
			if model.details.action_index > #ACTIONS then model.details.action_index = #ACTIONS end
			sync_legacy_state(model)
		elseif pressed_any(msg, { 'enter', 'return' }) and model.focus == 'details' and model.details.mode == 'actions' then
			perform_action(model, schema, batch)
		elseif pressed_any(msg, { 'enter', 'return' }) then
			if schema.mutable and model.results.selected == 1 then
				enter_create(model, schema, batch)
			elseif item and schema.mutable then
				enter_detail(model, batch)
			end
		elseif input.pressed(msg, 'left') and model.focus == 'results' then
			switch_entity(model, -1)
		elseif input.pressed(msg, 'right') and model.focus == 'results' then
			switch_entity(model, 1)
		elseif (input.pressed(msg, 'up') or input.pressed(msg, 'k')) and model.focus == 'results' then
			model.results.selected = model.results.selected - 1
			clamp_selection(model)
		elseif (input.pressed(msg, 'down') or input.pressed(msg, 'j')) and model.focus == 'results' then
			model.results.selected = model.results.selected + 1
			clamp_selection(model)
		elseif input.pressed(msg, 'ctrl+l') then
			model.results.filter = ''
			batch.push(model.search_input.msg.clear)
			model.message = 'Filter je ociscen.'
			sync_legacy_state(model)
		elseif msg.id == 'line_input:text_changed' and msg.data.uid == model.search_input.uid then
			model.results.filter = msg.data.text
			model.results.selected = 1
			enter_list(model, batch)
			clamp_selection(model)
		elseif msg.id == 'line_input:text_changed' and msg.data.uid == model.relation_search_input.uid then
			model.modal.relation_filter = msg.data.text
			model.modal.relation_selected = 1
			clamp_relation_selection(model)
		end

		return model, batch
	end,

	view = function(model, buf)
		if not model.ready then return end

		local schema = Store.selected_schema(model)
		local visible = Store.filtered_rows(model)
		local current = current_item(model)

		Header.view(model, buf, schema, Store.db, Store.schemas)
		SearchBox.view(model, buf)
		RecordList.view(model, buf, schema, visible)
		DetailPanel.view(model, buf, schema, current, ACTIONS, EDIT_ACTIONS, CREATE_ACTIONS)
		RelationModal.view(model, buf, relation_rows(model))
		InputDialog.view(model, buf)
	end
}
