local Style = require 'components.style'
local Fieldset = require 'components.fieldset'

local RecordList = {}

local function row_count(schema, visible)
	return schema.mutable and (#visible + 1) or #visible
end

local function row_item(schema, visible, idx)
	if schema.mutable then
		if idx == 1 then return { create = true } end
		return visible[idx - 1]
	end
	return visible[idx]
end

local function draw_create(buf)
	buf:write('+ Create new record')
end

local function write_highlighted(buf, text, query)
	if query == '' then
		buf:write(text)
		return
	end

	local lower_text = text:lower()
	local lower_query = query:lower()
	local pos = 1

	while true do
		local start_pos, end_pos = lower_text:find(lower_query, pos, true)
		if not start_pos then
			buf:write(text:sub(pos))
			break
		end

		if start_pos > pos then
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

function RecordList.view(model, buf, schema, visible)
	buf:with_offset(model.list_pos[1], model.list_pos[2], function()
		Fieldset.draw(model.list_fieldset, buf, model.list_layout, function()
			local total = row_count(schema, visible)
			if total == 0 then
				Style.write_line(buf, 'Nema zapisa za trenutni filter.', '#c08080', 'italic')
				return
			end

			local max_rows = math.max(1, model.list_layout.ih)
			local start = math.max(1, model.selected - max_rows + 1)
			if start + max_rows - 1 > total then
				start = math.max(1, total - max_rows + 1)
			end
			for screen_row = 0, max_rows - 1 do
				local idx = start + screen_row
				local item = row_item(schema, visible, idx)
				if item then
					if idx == model.selected then
						buf:set_fg('#f5d76e')
						buf:set_attr('bold')
						buf:write('> ')
					else
						buf:set_fg('#6f7f96')
					end
					buf:set_fg(nil)
					buf:set_attr(nil)
					if item.create then
						draw_create(buf)
					else
						write_highlighted(buf, schema.summary(item.row), model.filter)
					end
					if screen_row < max_rows - 1 then buf:write('\n') end
				end
			end
		end)
	end)
end

return RecordList
