local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'appointments', title = 'Appointments', navTitle = 'Appointments', searchPlaceholder = 'Patient, procedure, specialist...',
	fields = {
		{ key = 'patient_id', label = 'Patient', relation = 'patients' },
		{ key = 'procedure_id', label = 'Procedure', relation = 'procedures' },
		{ key = 'scheduledAt', label = 'Scheduled at' },
		{ key = 'specialist_id', label = 'Specialist', relation = 'doctors' },
	},
	defaults = { patient_id = '', procedure_id = '', scheduledAt = '', specialist_id = '' },
	summaryText = function(r)
		return tostring(r)
	end,
}
