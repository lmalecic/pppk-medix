local Style = require 'components.style'
local Fieldset = require 'components.fieldset'

local DetailPanel = {}

function DetailPanel.view(model, buf, schema, current)
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
				Style.write_line(buf, 'Akcije ce biti dostupne kroz gumbe.', '#8aa2c1', nil)
			else
				Style.write_line(buf, 'Read-only: lijecnici se definiraju pri prvom pokretanju.', '#c9a66b', nil)
			end
		end)
	end)
end

return DetailPanel
