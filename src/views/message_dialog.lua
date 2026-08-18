local Window = require 'components.window'

local MessageDialog = {}
MessageDialog.__index = MessageDialog

function MessageDialog.new()
	return setmetatable({}, MessageDialog)
end

local function writeWrapped(buf, text, width)
	local line = ''
	for word in tostring(text or ''):gmatch('%S+') do
		if #word > width then
			if line ~= '' then buf:write(line .. '\n'); line = '' end
			while #word > width do buf:write(word:sub(1, width) .. '\n'); word = word:sub(width + 1) end
		end
		if line == '' then line = word
		elseif #line + #word + 1 <= width then line = line .. ' ' .. word
		else buf:write(line .. '\n'); line = word end
	end
	if line ~= '' then buf:write(line) end
end

function MessageDialog:view(message, buf, layout)
	if not message then return end
	buf:with_offset(layout.message.x, layout.message.y, function()
		Window.title(layout.message.window, message.title or 'Message')
		Window.draw(layout.message.window, buf, layout.message.resolved, function(width)
			if message.kind == 'error' then
				buf:set_fg('#c08080')
			elseif message.kind == 'success' then
				buf:set_fg('#80b890')
			else
				buf:set_fg('#8aa2c1')
			end
			writeWrapped(buf, message.text or '', width)
			buf:set_fg(nil)
			buf:write('\n\n')
			buf:set_fg('#6f7f96'); buf:write('ENTER or ESC to close'); buf:set_fg(nil)
		end)
	end)
end

return MessageDialog
