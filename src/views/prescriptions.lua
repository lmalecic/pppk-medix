local LineInput = require 'mate.components.line_input'
local Window = require 'components.window'
local Style = require 'components.style'

local PrescriptionsView = {}
PrescriptionsView.__index = PrescriptionsView

function PrescriptionsView.new()
	return setmetatable({}, PrescriptionsView)
end

local function prefix(buf, selected, destructive)
	if selected then
		buf:set_fg(destructive and Style.colors.error or Style.colors.selected_cursor)
		buf:set_attr(Style.attributes.strong)
		buf:write(destructive and Style.symbols.deletionSelection or Style.symbols.selection)
	else
		buf:set_fg(Style.colors.muted)
	end
	buf:set_fg(nil); buf:set_attr(nil)
end

local function separator(buf, width)
	buf:set_fg(Style.colors.separator)
	buf:write(string.rep(Style.symbols.horizontalDivider, math.max(1, width - 1)))
	buf:set_fg(nil)
end

function PrescriptionsView:view(controller, state, buf, layout)
	buf:with_offset(layout.overlay.x, layout.overlay.y, function()
		local title = state.scope.history and 'Medications for Patient History' or 'Medication Prescriptions'
		Window.title(layout.overlay.window, title)
		Window.draw(layout.overlay.window, buf, layout.overlay.resolved, function(width, height)
			buf:set_fg(Style.colors.border); buf:set_attr(Style.attributes.strong); buf:write(Style.symbols.selection); buf:set_fg(nil); buf:set_attr(nil)
			LineInput.view(state.searchInput, buf); buf:write('\n'); separator(buf, width); buf:write('\n')
			local count = controller:rowCount(state)
			if count == 0 then buf:write('No prescriptions found.') end
			for index = 1, math.min(count, math.max(1, height - 5)) do
				local row = controller:rowAt(state, index)
				local selected = index == state.selected
				local destructive = state.scope.history and not rawget(row, 'prescribe')
				prefix(buf, selected, destructive)
				if selected then
					buf:set_fg(destructive and Style.colors.error or Style.colors.selected)
					buf:set_attr(Style.attributes.strong)
				end
				if rawget(row, 'prescribe') then buf:write('+ Prescribe a new medication') else buf:write(controller:label(row, state)) end
				buf:set_fg(nil); buf:set_attr(nil)
				buf:write('\n')
			end
			if state.scope.history then
				buf:write('\n'); buf:set_fg(Style.colors.muted); buf:write('ENTER prescribes or removes the selected medication; ESC returns'); buf:set_fg(nil)
			end
		end)
	end)
	if state.mode == 'picker' then
		buf:with_offset(layout.modal.x, layout.modal.y, function()
			Window.title(layout.modal.window, 'Prescribe a medication')
			Window.draw(layout.modal.window, buf, layout.modal.resolved, function(width, height)
				buf:set_fg(Style.colors.border); buf:set_attr(Style.attributes.strong); buf:write(Style.symbols.selection); buf:set_fg(nil); buf:set_attr(nil)
				LineInput.view(state.pickerInput, buf); buf:write('\n'); separator(buf, width); buf:write('\n')
				if #state.pickerRows == 0 then buf:write('No medications found.') end
				for index, medication in ipairs(state.pickerRows) do
					if index > height - 4 then break end
					local selected = index == state.pickerSelected
					prefix(buf, selected, false)
					if selected then buf:set_fg(Style.colors.selected); buf:set_attr(Style.attributes.strong) end
					buf:write(tostring(medication.name or '-'))
					buf:write(' | ' .. tostring(medication.dosage or '-') .. ' | ' .. tostring(medication.frequency or '-'))
					buf:set_fg(nil); buf:set_attr(nil)
					buf:write('\n')
				end
			end)
		end)
	end
end

return PrescriptionsView
