local Style = {}

function Style.write_line(buf, text, color, attr)
	if color then buf:set_fg(color) end
	if attr then buf:set_attr(attr) end
	buf:write(text)
	buf:set_fg(nil)
	buf:set_attr(nil)
end

function Style.draw_kv(buf, label, value)
	buf:set_fg('#8aa2c1')
	buf:write(label .. ': ')
	buf:set_fg(nil)
	buf:write(tostring(value or ''))
end

return Style
