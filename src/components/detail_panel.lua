local Style = require 'components.style'
local Fieldset = require 'components.fieldset'

local DetailPanel = {}

local function draw_actions(model, buf, actions)
	for i, action in ipairs(actions) do
		if model.focus == 'detail' and model.action_index == i then
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
	buf:write(model.focus == 'detail' and '↑/↓ odabir, ENTER potvrda, ESC natrag' or 'ENTER za odabir akcije')
	buf:set_fg(nil)
end

function DetailPanel.view(model, buf, schema, current, actions)
	local title = schema.title
	if current then title = title .. ' #' .. current.row.id end
	Fieldset.title(model.detail_fieldset, title)

	buf:with_offset(model.detail_pos[1], model.detail_pos[2], function()
		Fieldset.draw(model.detail_fieldset, buf, model.detail_layout, function()
			if not current then
				Style.write_line(buf, 'Odaberi ili dodaj zapis.', '#8aa2c1', nil)
				return
			end

			for _, field in ipairs(schema.fields) do
				Style.draw_kv(buf, field, current.row[field])
				buf:write('\n')
			end
			buf:write('\n')
			if schema.mutable then
				draw_actions(model, buf, actions)
			else
				Style.write_line(buf, 'Read-only: lijecnici se definiraju pri prvom pokretanju.', '#c9a66b', nil)
			end
		end)
	end)
end

return DetailPanel
