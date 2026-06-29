local LineInput = require 'mate.components.line_input'
local Fieldset = require 'components.fieldset'

local SearchBox = {}

function SearchBox.view(model, buf)
	buf:with_offset(model.search_pos[1], model.search_pos[2], function()
		Fieldset.draw(model.search_fieldset, buf, model.search_layout, function()
			LineInput.view(model.search_input, buf)
		end)
	end)
end

return SearchBox
