local LineSeparator = {}

function LineSeparator.draw(buf, width)
	buf:set_fg('#303640')
	buf:write(string.rep('─', math.max(0, width)))
	buf:set_fg(nil)
end

return LineSeparator
