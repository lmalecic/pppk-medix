local LineInput = require 'mate.components.line_input'
local LineSeparator = require 'components.line_separator'
local Window = require 'components.window'

local RelationModal = {}

local function apply_base_style(buf, base_color, base_bold)
	if base_color then buf:set_fg(base_color) end
	if base_bold then buf:set_attr('bold') end
end

local function write_highlighted(buf, text, query, base_color, base_bold)
	if query == '' then
		apply_base_style(buf, base_color, base_bold)
		buf:write(text)
		return
	end

	local lower_text = text:lower()
	local lower_query = query:lower()
	local pos = 1

	while true do
		local start_pos, end_pos = lower_text:find(lower_query, pos, true)
		if not start_pos then
			apply_base_style(buf, base_color, base_bold)
			buf:write(text:sub(pos))
			break
		end

		if start_pos > pos then
			apply_base_style(buf, base_color, base_bold)
			buf:write(text:sub(pos, start_pos - 1))
		end

		buf:set_fg('#c08080')
		buf:set_attr('bold')
		buf:write(text:sub(start_pos, end_pos))
		buf:set_attr(nil)
		buf:set_fg(nil)

		pos = end_pos + 1
	end
end

local function draw_row(buf, label, selected, current, query)
	if selected then
		buf:set_fg('#f5d76e')
		buf:set_attr('bold')
		buf:write('> ')
	else
		buf:set_fg('#6f7f96')
	end
	buf:set_attr(nil)
	buf:set_fg(nil)

	if current then
		write_highlighted(buf, label, query, '#f5d76e', true)
	else
		write_highlighted(buf, label, query)
	end
	buf:set_attr(nil)
	buf:set_fg(nil)
end

local function draw_search(buf, model)
	buf:set_fg('#303640')
	buf:set_attr('bold')
	buf:write('> ')
	buf:set_attr(nil)
	buf:set_fg(nil)
	LineInput.view(model.relation_search_input, buf)
end

local function draw_results(buf, model, rows, height)
	if #rows == 0 then
		buf:set_fg('#c08080')
		buf:set_attr('italic')
		buf:write('Nema rezultata.')
		buf:set_attr(nil)
		buf:set_fg(nil)
		return
	end

	local max_rows = math.max(1, height)
	local start = math.max(1, model.relation_selected - max_rows + 1)
	for screen_row = 0, max_rows - 1 do
		local item = rows[start + screen_row]
		if item then
			draw_row(
				buf,
				item.label,
				start + screen_row == model.relation_selected,
				tostring(item.row.id) == tostring(model.relation_current_id),
				model.modal.relation_filter
			)
			if screen_row < max_rows - 1 then buf:write('\n') end
		end
	end
end

function RelationModal.view(model, buf, rows)
	if model.focus ~= 'modal' or model.modal.type ~= 'relation' then return end

	buf:with_offset(model.relation_window_pos[1], model.relation_window_pos[2], function()
		Window.draw(model.relation_window, buf, model.relation_window_layout, function(w, h)
			draw_search(buf, model)
			buf:write('\n')
			LineSeparator.draw(buf, w)
			buf:write('\n')
			draw_results(buf, model, rows, h - 2)
		end)
	end)
end

return RelationModal
