local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'patient_histories', title = 'Medical History', navTitle = 'History', searchPlaceholder = 'Diagnosis, patient, doctor...',
	fields = {
		{ key = 'patient_id', label = 'Patient', relation = 'patients' },
		{ key = 'diagnosis', label = 'Diagnosis' },
		{ key = 'fromDate', label = 'From date' },
		{ key = 'toDate', label = 'To date' },
		{ key = 'doctor_id', label = 'Doctor', relation = 'doctors' },
	},
	defaults = { patient_id = '', diagnosis = '', fromDate = '', toDate = '', doctor_id = '' },
	summaryText = function(r)
		return H.text(r.diagnosis) .. ' | ' .. H.text(r.fromDate) .. ' - ' .. H.text(r.toDate)
	end,
	detailsText = function(r)
		return {
			'Patient: ' .. H.relation(r, 'patient', 'patient_id', H.person),
			'Doctor: ' .. H.relation(r, 'doctor', 'doctor_id', H.person),
			'Medications: select Manage Medications below',
		}
	end,
	actions = {
		{ label = 'Manage Medications', type = 'manage_prescriptions' },
	},
}
