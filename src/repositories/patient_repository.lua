local BaseRepository = require 'repositories.base_repository'

local PatientRepository = {}
PatientRepository.__index = PatientRepository
setmetatable(PatientRepository, { __index = BaseRepository })

function PatientRepository.new()
	return setmetatable(BaseRepository.new('patients'), PatientRepository)
end

function PatientRepository:delete(patient)
	-- TODO(ORM): Reject deletion when patientHistories or appointments contains
	-- a row for patient.id. Otherwise remove the patient and saveChanges().
	return nil, 'ORM patient deletion is not implemented.'
end

return PatientRepository
