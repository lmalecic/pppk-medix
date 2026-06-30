local LineInput = require 'mate.components.line_input'
local Window = require 'components.window'

local InputDialog = {}

local function write_right(buf, width, text)
	local pad = math.max(0, width - #text)
	if pad > 0 then buf:write(string.rep(' ', pad)) end
	buf:write(text)
end

function InputDialog.view(model, buf)
	if model.focus ~= 'modal' or model.modal.type ~= 'value' then return end

	buf:with_offset(model.value_dialog_pos[1], model.value_dialog_pos[2], function()
		Window.draw(model.value_window, buf, model.value_window_layout, function(w)
			buf:set_fg('#303640')
			buf:set_attr('bold')
			buf:write('> ')
			buf:set_attr(nil)
			buf:set_fg(nil)
			LineInput.view(model.value_input, buf)
			buf:write('\n')
			buf:set_fg('#6f7f96')
			write_right(buf, w, 'ENTER confirm, ESC cancel')
			buf:set_fg(nil)
		end)
	end)
end

return InputDialog
