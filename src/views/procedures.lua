local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'procedures', title = 'Procedures', navTitle = 'Procedures', searchPlaceholder = 'Procedure name...',
	fields = { { key = 'name', label = 'Name' } },
	defaults = { name = '' },
	summaryText = function(r) return H.text(r.name) end,
	actions = {
		{ label = 'View Appointments', type = 'open_entity', target = 'appointments', scopeMethod = 'byProcedure', lockField = 'procedure_id' },
	},
}
