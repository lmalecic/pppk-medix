local Fieldset = require 'components.fieldset'
local Window = require 'components.window'

local Layout = {}
Layout.__index = Layout

local function fieldset(title, x, y, width, height)
	local value = { x = x, y = y, fieldset = Fieldset.init(title) }
	Fieldset.width(value.fieldset, width); Fieldset.height(value.fieldset, height)
	value.resolved = Fieldset.resolve(value.fieldset)
	return value
end

local function window(title, x, y, width, height)
	local value = { x = x, y = y, window = Window.init(title) }
	Window.width(value.window, width); Window.height(value.window, height)
	value.resolved = Window.resolve(value.window)
	return value
end

function Layout.new(width, height)
	local self = setmetatable({}, Layout)
	self:resize(width, height)
	return self
end

function Layout:resize(width, height)
	self.width, self.height = width, height
	self.header = fieldset('MediX v0.1', 1, 1, math.max(24, width - 1), 3)
	local leftWidth = math.max(24, math.floor((width - 2) * 0.52))
	self.search = fieldset('Search', 1, 4, leftWidth, 3)
	self.list = fieldset('Results', 1, 7, leftWidth, math.max(5, height - 7))
	self.details = fieldset('', self.list.resolved.total_w + 2, 4,
		math.max(24, width - self.list.resolved.total_w - 2), math.max(5, height - 4))
	local overlayWidth = math.min(math.max(48, math.floor(width * 0.76)), math.max(48, width - 6))
	local overlayHeight = math.min(math.max(18, math.floor(height * 0.78)), math.max(18, height - 4))
	self.overlay = window('', math.max(1, math.floor((width - overlayWidth) / 2)),
		math.max(1, math.floor((height - overlayHeight) / 2)), overlayWidth, overlayHeight)
	local modalWidth = math.min(math.max(38, math.floor(width * 0.58)), math.max(38, width - 8))
	local modalHeight = math.min(math.max(12, math.floor(height * 0.58)), math.max(12, height - 6))
	self.modal = window('', math.max(1, math.floor((width - modalWidth) / 2)),
		math.max(1, math.floor((height - modalHeight) / 2)), modalWidth, modalHeight)
	local inputWidth = math.min(math.max(34, math.floor(width * 0.46)), math.max(34, width - 10))
	self.input = window('', math.max(1, math.floor((width - inputWidth) / 2)), math.max(2, math.floor((height - 4) / 2)), inputWidth, 4)
	local messageWidth = math.min(math.max(42, math.floor(width * 0.5)), math.max(42, width - 8))
	self.message = window('Message', math.max(1, math.floor((width - messageWidth) / 2)), math.max(2, math.floor((height - 7) / 2)), messageWidth, 7)
end

return Layout
