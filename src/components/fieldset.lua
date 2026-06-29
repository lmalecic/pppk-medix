local Box = require 'mate.box'

local Fieldset = {}

local function title_text(title)
	if not title or title == '' then return nil end
	return ' ' .. title .. ' '
end

function Fieldset.init(title)
	local box = Box()
		.border(true)
		.border_color('#303640')
		.padding(0, 1, 0, 1)

	return {
		title = title,
		box = box,
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
			buf:set_fg('#d7e1ee')
			buf:set_attr('bold')
			buf:write(title)
			buf:set_attr(nil)
			buf:set_fg(nil)
		end)
	end
end

return Fieldset
