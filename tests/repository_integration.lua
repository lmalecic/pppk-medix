package.path = 'src/?.lua;src/?/init.lua;' .. package.path

require 'populateData'

local DateTime = require 'util.date-time'
local repositories = require 'repositories'

local suffix = tostring(os.time())
local patient = assert(repositories.patients:create {
	firstName = 'Demo', lastName = 'Patient', oib = suffix:sub(-11, -1):rep(2):sub(1, 11),
	dateOfBirth = DateTime.new(1990, 5, 12), sex = 'F',
	permanentAddress = 'Test address 1', secondaryAddress = 'Test address 2',
})
local medication = assert(repositories.medications:create {
	name = 'Integration medication ' .. suffix, dosage = '10 mg', frequency = 'Once daily',
})
local duplicateSucceeded = pcall(function()
	repositories.medications:create { name = medication.name, dosage = '5 mg', frequency = 'Twice daily' }
end)
assert(not duplicateSucceeded, 'the database must reject a duplicate medication')
local recoveredMedication = assert(repositories.medications:create {
	name = 'Integration recovery medication ' .. suffix, dosage = '5 mg', frequency = 'Twice daily',
})
local procedure = assert(repositories.procedures:create { name = 'Integration procedure ' .. suffix })
local specialization = assert(repositories.specializations:create { name = 'Integration specialization ' .. suffix })
local doctor = assert(repositories.doctors:list(nil, '')[1])
local history = assert(repositories.patient_histories:create {
	patient_id = patient.id, doctor_id = doctor.id, diagnosis = 'Integration diagnosis',
})
local appointment = assert(repositories.appointments:create {
	patient_id = patient.id, specialist_id = doctor.id, procedure_id = procedure.id,
	scheduledAt = DateTime.new(2030, 6, 15, 10, 30, 0),
})
assert(repositories.prescriptions:prescribe(history.id, medication))

assert(#repositories.patients:list(nil, 'Demo') >= 1)
local matchingHistories = repositories.patient_histories:list({ method = 'byPatient', id = patient.id }, 'diagnosis')
assert(#matchingHistories == 1)
assert(#matchingHistories[1].medications == 1)
assert(tostring(matchingHistories[1].medications[1].medication):find('Integration medication', 1, true))
local matchingAppointments = repositories.appointments:list({ method = 'byPatient', id = patient.id }, 'procedure')
assert(#matchingAppointments == 1)
assert(getmetatable(matchingAppointments[1].scheduledAt) == DateTime)
assert(#repositories.prescriptions:listByHistory(history.id, '') == 1)

assert(repositories.medications:update(medication, {
	name = medication.name, dosage = '20 mg', frequency = medication.frequency,
}))
assert(repositories.appointments:delete(appointment))
assert(repositories.patient_histories:delete(history)) -- also removes its prescription
assert(repositories.medications:delete(medication))
assert(repositories.medications:delete(recoveredMedication))
assert(repositories.patients:delete(patient))
assert(repositories.procedures:delete(procedure))
assert(repositories.specializations:delete(specialization))

print('repository_integration: ok')
