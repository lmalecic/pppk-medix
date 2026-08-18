--- Basic DateTime implementation without timezones

--- @class DateTime
--- @field year number
--- @field month number
--- @field day number
--- @field hour number
--- @field minute number
--- @field second number
local DateTime = {}
DateTime.__index = DateTime

--- Creates a new DateTime instance with given parameters.
--- Year, month, day, hour, minute, second are optional and default to 1970, 1, 1, 0, 0, 0 respectively.
--- Passing decimal values for any of these except for second will be rounded down to the nearest integer.
--- @param year number?
--- @param month number?
--- @param day number?
--- @param hour number?
--- @param minute number?
--- @param second number?
function DateTime.new(year, month, day, hour, minute, second)
    assert(tonumber(year) ~= nil, "year is not a number")
    assert(tonumber(month) ~= nil, "month is not a number")
    assert(tonumber(day) ~= nil, "day is not a number")
    assert(tonumber(hour) ~= nil, "hour is not a number")
    assert(tonumber(minute) ~= nil, "minute is not a number")
    assert(tonumber(second) ~= nil, "second is not a number")
    return setmetatable({
        year = year and math.floor(year) or 1970,
        month = month and math.floor(month) or 1,
        day = day and math.floor(day) or 1,
        hour = hour and math.floor(hour) or 0,
        minute = minute and math.floor(minute) or 0,
        second = second or 0,
    }, DateTime)
end

function DateTime.now()
    local now = os.date("*t")
    return DateTime.new(now.year, now.month, now.day, now.hour, now.min, now.sec)
end

--- @return DateTime
function DateTime.fromString(dateTimeString)
    --- FORMAT: 2026-08-18 13:40:53.065341
    local y, m, d, h, min, s = dateTimeString:match("^(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local y_num = assert(tonumber(y), "Invalid dateTimeString format: year is not a number")
    local m_num = assert(tonumber(m), "Invalid dateTimeString format: month is not a number")
    local d_num = assert(tonumber(d), "Invalid dateTimeString format: day is not a number")
    local h_num = assert(tonumber(h), "Invalid dateTimeString format: hour is not a number")
    local min_num = assert(tonumber(min), "Invalid dateTimeString format: minute is not a number")
    local s_num = assert(tonumber(s), "Invalid dateTimeString format: second is not a number")
    return DateTime.new(y_num, m_num, d_num, h_num, min_num, s_num)
end

--- @param timestamp number
function DateTime.fromUnixTimestamp(timestamp)
    local now = os.date("*t", timestamp)
    return DateTime.new(now.year, now.month, now.day, now.hour, now.min, now.sec)
end

--- @return number
function DateTime:toUnixTimestamp()
    return os.time({ year = self.year, month = self.month, day = self.day, hour = self.hour, min = self.minute, sec = self.second })
end

function DateTime:__tostring()
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", self.year, self.month, self.day, self.hour, self.minute, self.second)
end

function DateTime:__eq(other)
    if type(other) == "string" then
        return tostring(self) == other
    end

    if type(other) == "number" then
        return self:toUnixTimestamp() == other
    end

    if getmetatable(other) ~= DateTime then
        return false
    end

    return self.year == other.year and self.month == other.month and self.day == other.day and self.hour == other.hour and
        self.minute == other.minute and self.second == other.second
end

function DateTime:__lt(other)
    if type(other) == "string" then
        local success, result = pcall(DateTime.fromString, other)
        if not success then
            error("Cannot compare DateTime with string " .. other .. "; " .. result)
        end
        return self:toUnixTimestamp() < result:toUnixTimestamp()
    end

    if type(other) == "number" then
        return self:toUnixTimestamp() < other
    end

    assert(type(other) == "table", "Cannot compare DateTime with " .. type(other))

    if getmetatable(other) ~= DateTime then
        error("Cannot compare DateTime with " .. tostring(other))
    end

    return self:toUnixTimestamp() < other:toUnixTimestamp()
end

return DateTime
