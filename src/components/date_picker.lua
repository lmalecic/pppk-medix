local input = require 'mate.input'
local DateTime = require 'util.date-time'
local Style = require 'components.style'

local DatePicker = {}
DatePicker.__index = DatePicker

local function pressed(msg, ...)
	for index = 1, select('#', ...) do
		if input.pressed(msg, select(index, ...)) then return true end
	end
	return false
end

local parts = {
	{ key = 'year', width = 4, min = 1, max = 9999 },
	{ key = 'month', width = 2, min = 1, max = 12 },
	{ key = 'day', width = 2, min = 1, max = 31 },
	{ key = 'hour', width = 2, min = 0, max = 23 },
	{ key = 'minute', width = 2, min = 0, max = 59 },
	{ key = 'second', width = 2, min = 0, max = 59 },
}

local function leap(year) return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) end
local function days(year, month)
	if month == 2 then return leap(year) and 29 or 28 end
	if month == 4 or month == 6 or month == 9 or month == 11 then return 30 end
	return 31
end

function DatePicker.new(value)
	local source = value
	if type(source) == 'string' and source ~= '' then
		local ok, parsed = pcall(DateTime.fromString, source); source = ok and parsed or nil
	end
	if getmetatable(source) ~= DateTime then source = DateTime.now() end
	return setmetatable({ value = DateTime.new(source.year, source.month, source.day, source.hour, source.minute, source.second), selected = 1, typed = nil }, DatePicker)
end

function DatePicker:maximum(part)
	return part.key == 'day' and days(self.value.year, self.value.month) or part.max
end

function DatePicker:typedIsValid()
	if not self.typed then return true end
	local part, value = parts[self.selected], tonumber(self.typed)
	return value ~= nil and value >= part.min and value <= self:maximum(part)
end

function DatePicker:typeDigit(digit)
	local part = parts[self.selected]
	local typed = (self.typed or '') .. tostring(digit)
	if #typed > part.width then typed = tostring(digit) end
	self.typed = typed
	if self:typedIsValid() then
		self.value[part.key] = tonumber(typed)
		self.value.day = math.min(self.value.day, days(self.value.year, self.value.month))
		if #typed == part.width and self.selected < #parts then
			self.selected, self.typed = self.selected + 1, nil
		end
	end
end

function DatePicker:move(amount)
	self.selected = math.max(1, math.min(#parts, self.selected + amount))
	self.typed = nil
end

function DatePicker:adjust(amount)
	local part = parts[self.selected]
	local maximum = self:maximum(part)
	local value = self.value[part.key] + amount
	if value > maximum then value = part.min elseif value < part.min then value = maximum end
	self.value[part.key] = value
	self.value.day = math.min(self.value.day, days(self.value.year, self.value.month))
	self.typed = nil
end

function DatePicker:update(msg)
	local digit = input.num(msg)
	if digit ~= nil then self:typeDigit(digit)
	elseif pressed(msg, 'backspace') and self.typed then
		self.typed = self.typed:sub(1, -2)
		if self.typed == '' then self.typed = nil elseif self:typedIsValid() then self.value[parts[self.selected].key] = tonumber(self.typed) end
	elseif pressed(msg, 'left', 'h') then self:move(-1)
	elseif pressed(msg, 'right', 'l') then self:move(1)
	elseif pressed(msg, 'up', 'k') then self:adjust(1)
	elseif pressed(msg, 'down', 'j') then self:adjust(-1)
	elseif pressed(msg, 'enter', 'return') and self:typedIsValid() then return 'confirm', self.value
	elseif pressed(msg, 'esc', 'escape') then return 'cancel' end
end

function DatePicker:view(buf)
	local separators = { '-', '-', ' ', ':', ':' }
	for index, part in ipairs(parts) do
		if index == self.selected then
			buf:set_fg(self:typedIsValid() and Style.colors.selected or Style.colors.error)
			buf:set_attr(Style.attributes.strong)
		end
		local text = string.format('%0' .. part.width .. 'd', self.value[part.key])
		if index == self.selected and self.typed then text = self.typed .. string.rep('·', part.width - #self.typed) end
		buf:write(text)
		buf:set_fg(nil); buf:set_attr(nil)
		if separators[index] then buf:write(separators[index]) end
	end
end

return DatePicker
