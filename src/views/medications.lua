local EntityView = require 'views.entity_view'
local H = require 'views.helpers'

return EntityView.new {
	key = 'medications', title = 'Medications', navTitle = 'Medications', searchPlaceholder = 'Name, dosage, frequency...',
	fields = {
		{ key = 'name', label = 'Name' },
		{ key = 'dosage', label = 'Dosage' },
		{ key = 'frequency', label = 'Frequency' },
	},
	defaults = { name = '', dosage = '', frequency = '' },
	summaryText = function(r)
		return H.text(r.name) .. ' | ' .. H.text(r.dosage) .. ' | ' .. H.text(r.frequency)
	end,
	actions = {
		{ label = 'View Prescriptions', type = 'open_prescriptions' },
	},
}
