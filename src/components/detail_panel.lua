local Style = require 'components.style'
local Fieldset = require 'components.fieldset'
local Store = require 'store'

local DetailPanel = {}

local function is_editing(model)
	return model.details and (model.details.mode == 'edit' or model.details.mode == 'create')
end

local function is_actions(model)
	return model.focus == 'details' and model.details and model.details.mode == 'actions'
end

local function draw_actions(model, buf, actions)
	for i, action in ipairs(actions) do
		if is_actions(model) and model.action_index == i then
			buf:set_fg('#f5d76e')
			buf:set_attr('bold')
			buf:write('> ')
		else
			buf:set_fg('#6f7f96')
		end
		buf:set_fg(nil)
		buf:set_attr(nil)
		buf:write(action)
		if i < #actions then buf:write('\n') end
	end
	buf:write('\n\n')
	buf:set_fg('#6f7f96')
	buf:write(is_actions(model) and '↑/↓ select, ENTER confirm, ESC back' or 'ENTER for action selection')
	buf:set_fg(nil)
end

local function draw_selector_prefix(buf, selected)
	if selected then
		buf:set_fg('#f5d76e')
		buf:set_attr('bold')
		buf:write('> ')
		buf:set_attr(nil)
		buf:set_fg(nil)
	end
end

local function draw_fields(model, buf, schema, current)
	for i, field in ipairs(schema.fields) do
		local selected = is_editing(model) and model.edit_index == i
		local relation = Store.relation_for(field)
		local row = is_editing(model) and model.edit_draft or current.row

		draw_selector_prefix(buf, selected)
		Style.draw_kv(buf, field, '')
		buf:write(tostring(row[field] or ''))

		if relation and selected then
			buf:set_fg('#6f7f96')
			buf:write('  ENTER select')
			buf:set_fg(nil)
		end

		if i < #schema.fields then buf:write('\n') end
	end
end

local function draw_edit_actions(model, buf, schema, actions)
	for i, action in ipairs(actions) do
		local index = #schema.fields + i
		local selected = is_editing(model) and model.edit_index == index

		draw_selector_prefix(buf, selected)
		buf:write(action)
		if i < #actions then buf:write('\n') end
	end
end

function DetailPanel.view(model, buf, schema, current, actions, edit_actions, create_actions)
	local title = schema.title
	if model.details and model.details.mode == 'create' then title = 'New record' end
	if current then title = title .. ' #' .. current.row.id end
	Fieldset.title(model.detail_fieldset, title)

	buf:with_offset(model.detail_pos[1], model.detail_pos[2], function()
		Fieldset.draw(model.detail_fieldset, buf, model.detail_layout, function()
			if not current and not (model.details and model.details.mode == 'create') then
				Style.write_line(buf, 'Create a new record.', '#8aa2c1', nil)
				return
			end

			if schema.mutable then
				if is_editing(model) then
					draw_fields(model, buf, schema, current)
					buf:write('\n\n')
					draw_edit_actions(model, buf, schema,
						model.details.mode == 'create' and create_actions or edit_actions)
					buf:write('\n\n')
					buf:set_fg('#6f7f96')
					buf:write('↑/↓ select, ENTER change, ESC cancel')
					buf:set_fg(nil)
				else
					draw_fields(model, buf, schema, current)
					buf:write('\n\n')
					draw_actions(model, buf, actions)
				end
			else
				draw_fields(model, buf, schema, current)
				buf:write('\n')
				Style.write_line(buf, 'Read-only: doctors are defined on initialization.', '#c9a66b', nil)
			end
		end)
	end)
end

return DetailPanel
