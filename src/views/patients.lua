local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'patients', title = 'Patients', navTitle = 'Patients', searchPlaceholder = 'Name, OIB, address...',
	fields = {
		{ key = 'firstName', label = 'First name' },
		{ key = 'lastName', label = 'Last name' },
		{ key = 'oib', label = 'OIB' },
		{ key = 'dateOfBirth', label = 'Date of birth' },
		{ key = 'sex', label = 'Sex' },
		{ key = 'permanentAddress', label = 'Permanent address' },
		{ key = 'secondaryAddress', label = 'Secondary address' },
	},
	defaults = { firstName = '', lastName = '', oib = '', dateOfBirth = '', sex = '', permanentAddress = '', secondaryAddress = '' },
	summaryText = function(r)
		return H.person(r) .. ' | OIB ' .. H.text(r.oib) .. ' | ' .. H.text(r.dateOfBirth)
	end,
	detailsText = function(r)
		return {
			'Sex: ' .. H.text(r.sex),
			'Permanent address: ' .. H.text(r.permanentAddress),
			'Secondary address: ' .. H.text(r.secondaryAddress),
		}
	end,
	actions = {
		{ label = 'View Patient History', type = 'open_entity', target = 'patient_histories', scopeMethod = 'byPatient', lockField = 'patient_id' },
		{ label = 'View Appointments', type = 'open_entity', target = 'appointments', scopeMethod = 'byPatient', lockField = 'patient_id' },
	},
}
