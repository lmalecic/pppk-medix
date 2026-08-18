local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'specializations', title = 'Specializations', navTitle = 'Specializations', searchPlaceholder = 'Specialization name...',
	fields = { { key = 'name', label = 'Name' } },
	defaults = { name = '' },
	summaryText = function(r) return H.text(r.name) end,
	actions = {
		{ label = 'View Doctors', type = 'open_entity', target = 'doctors', scopeMethod = 'bySpecialization', lockField = 'specialization_id' },
	},
}
