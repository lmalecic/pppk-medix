local Box = require 'mate.box'

local Window = {}

local function title_text(title)
	if not title or title == '' then return nil end
	return ' ' .. title .. ' '
end

local function reset_style(buf)
	buf:set_fg(nil)
	buf:set_bg(nil)
	buf:set_attr(nil)
end

local function clear_rect(buf, x, y, w, h)
	reset_style(buf)
	for row = 0, h - 1 do
		buf:move_to(x, y + row)
		buf:write(string.rep(' ', w))
	end
end

local function clear_content(buf, w, h)
	clear_rect(buf, 0, 0, w, h)
	buf:move_to(0, 0)
end

local function clear_window_interior(buf, layout)
	local x = layout.bx + layout.b_wl
	local y = layout.by + layout.b_ht
	local w = math.max(0, layout.bw - layout.b_wl - layout.b_wr)
	local h = math.max(0, layout.bh - layout.b_ht - layout.b_hb)
	clear_rect(buf, x, y, w, h)
end

function Window.init(title)
	local box = Box()
		.border(true)
		.border_color('#303640')
		.padding(0, 1, 0, 1)

	return {
		title = title,
		box = box,
	}
end

function Window.width(window, w)
	window.box.width(w)
	return window
end

function Window.height(window, h)
	window.box.height(h)
	return window
end

function Window.title(window, title)
	window.title = title
	return window
end

function Window.resolve(window)
	return window.box.resolve()
end

function Window.draw(window, buf, layout, content_fn)
	clear_window_interior(buf, layout)

	window.box.draw(buf, layout, function(w, h)
		clear_content(buf, w, h)
		if content_fn then content_fn(w, h) end
	end)

	local title = title_text(window.title)
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

return Window
