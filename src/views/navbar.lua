local Fieldset = require 'components.fieldset'
local Style = require 'components.style'

local Navbar = {}
Navbar.__index = Navbar

function Navbar.new(views)
	return setmetatable({ views = views }, Navbar)
end

function Navbar:view(model, buf)
	buf:with_offset(model.layout.header.x, model.layout.header.y, function()
		Fieldset.draw(model.layout.header.fieldset, buf, model.layout.header.resolved, function()
			for index, view in ipairs(self.views) do
				if index > 1 then
					buf:set_fg(Style.colors.separator)
					buf:write(Style.symbols.tabSeparator)
					buf:set_fg(nil)
				end
				if index == model.activeTab then
					buf:set_fg(Style.colors.selected)
					buf:set_attr(Style.attributes.strong)
				else
					buf:set_fg(Style.colors.secondary_text)
				end
				buf:write(view.navTitle or view.title)
				buf:set_attr(nil)
				buf:set_fg(nil)
			end
		end)
	end)
end

return Navbar
