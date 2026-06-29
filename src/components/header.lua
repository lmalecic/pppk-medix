local Fieldset = require 'components.fieldset'

local Header = {}

local function draw_tabs(buf, schemas, active_index)
	for i, schema in ipairs(schemas) do
		if i > 1 then
			buf:set_fg('#465468')
			buf:write(' | ')
			buf:set_fg(nil)
		end

		if i == active_index then
			buf:set_fg('#f5d76e')
			buf:set_attr('bold')
			buf:write(schema.title)
			buf:set_attr(nil)
			buf:set_fg(nil)
		else
			buf:set_fg('#8aa2c1')
			buf:write(schema.title)
			buf:set_fg(nil)
		end
	end
end

function Header.view(model, buf, schema, db, schemas)
	buf:with_offset(model.header_pos[1], model.header_pos[2], function()
		Fieldset.draw(model.header_fieldset, buf, model.header_layout, function(w)
			draw_tabs(buf, schemas, model.entity)
		end)
	end)
end

return Header
