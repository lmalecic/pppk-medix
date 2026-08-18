local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'doctors', title = 'Doctors', navTitle = 'Doctors', mutable = false, searchPlaceholder = 'Name, specialization...',
	fields = {
		{ key = 'firstName', label = 'First name', readonly = true },
		{ key = 'lastName', label = 'Last name', readonly = true },
		{ key = 'specialization_id', label = 'Specialization', relation = 'specializations', readonly = true },
	},
	summaryText = function(r)
		return tostring(r)
	end,
	detailsText = function()
		return { 'Read-only: doctors are defined during initialization.' }
	end,
	actions = {
		{ label = 'View Patient Histories', type = 'open_entity', target = 'patient_histories', scopeMethod = 'byDoctor', lockField = 'doctor_id' },
		{ label = 'View Appointments', type = 'open_entity', target = 'appointments', scopeMethod = 'byDoctor', lockField = 'specialist_id' },
	},
}
