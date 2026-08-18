local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'patient_histories', title = 'Medical History', navTitle = 'Medical History', searchPlaceholder = 'Diagnosis, patient, doctor...',
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
		local lines = { 'Medications:' }
		local ok, prescriptions = pcall(function() return r.medications end)
		prescriptions = ok and prescriptions or {}
		if #prescriptions == 0 then table.insert(lines, '  - None') end
		for index = 1, math.min(4, #prescriptions) do
			local prescription = prescriptions[index]
			local medication = prescription.medication
			table.insert(lines, '  - ' .. (medication and tostring(medication) or tostring(prescription)))
		end
		if #prescriptions > 4 then table.insert(lines, ' and ' .. tostring(#prescriptions - 4) .. ' more') end
		return lines
	end,
	actions = {
		{ label = 'Manage Medications', type = 'manage_prescriptions' },
	},
}
