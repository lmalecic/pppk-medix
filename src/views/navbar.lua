local Fieldset = require 'components.fieldset'

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
					buf:set_fg('#465468')
					buf:write(' | ')
					buf:set_fg(nil)
				end
				if index == model.activeTab then
					buf:set_fg('#f5d76e')
					buf:set_attr('bold')
				else
					buf:set_fg('#8aa2c1')
				end
				buf:write(view.navTitle or view.title)
				buf:set_attr(nil)
				buf:set_fg(nil)
			end
		end)
	end)
end

return Navbar
