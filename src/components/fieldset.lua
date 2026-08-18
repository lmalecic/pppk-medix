local Box = require 'mate.box'
local Style = require 'components.style'

local Fieldset = {}

local function title_text(title)
	if not title or title == '' then return nil end
	return ' ' .. title .. ' '
end

function Fieldset.init(title)
	local padding = Style.padding.fieldset
	local box = Box()
		.border(true)
		.border_color(Style.colors.border)
		.padding(padding[1], padding[2], padding[3], padding[4])

	return {
		title = title,
		box = box,
		clear = false,
	}
end

function Fieldset.width(fieldset, w)
	fieldset.box.width(w)
	return fieldset
end

function Fieldset.height(fieldset, h)
	fieldset.box.height(h)
	return fieldset
end

function Fieldset.title(fieldset, title)
	fieldset.title = title
	return fieldset
end

function Fieldset.resolve(fieldset)
	return fieldset.box.resolve()
end

function Fieldset.draw(fieldset, buf, layout, content_fn)
	fieldset.box.draw(buf, layout, content_fn)

	local title = title_text(fieldset.title)
	if title then
		buf:with_offset(layout.bx + 2, layout.by, function()
			buf:set_fg(Style.colors.title)
			buf:set_attr(Style.attributes.strong)
			buf:write(title)
			buf:set_attr(nil)
			buf:set_fg(nil)
		end)
	end
end

return Fieldset
