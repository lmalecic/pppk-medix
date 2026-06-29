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
	model.message = 'Prikaz: ' .. Store.selected_schema(model).title
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
		elseif input.pressed(msg, 'left') then
			switch_entity(model, -1)
		elseif input.pressed(msg, 'right') then
			switch_entity(model, 1)
		elseif input.pressed(msg, 'up') or input.pressed(msg, 'k') then
			model.selected = model.selected - 1
			clamp_selection(model)
		elseif input.pressed(msg, 'down') or input.pressed(msg, 'j') then
			model.selected = model.selected + 1
			clamp_selection(model)
		elseif input.pressed(msg, 'ctrl+l') then
			model.filter = ''
			batch.push(model.search_input.msg.clear)
			model.message = 'Filter je ociscen.'
		elseif msg.id == 'line_input:text_changed' and msg.data.uid == model.search_input.uid then
			model.filter = msg.data.text
			model.selected = 1
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
		DetailPanel.view(model, buf, schema, current)
	end
}
