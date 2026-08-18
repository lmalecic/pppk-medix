local BaseRepository = require 'repositories.base_repository'

local PatientHistoryRepository = {}
PatientHistoryRepository.__index = PatientHistoryRepository
setmetatable(PatientHistoryRepository, { __index = BaseRepository })

function PatientHistoryRepository.new()
	return setmetatable(BaseRepository.new('patientHistories'), PatientHistoryRepository)
end

function PatientHistoryRepository:list(scope)
	-- TODO(ORM): Return all histories, or filter by patient_id/doctor_id when
	-- scope.method is "byPatient"/"byDoctor".
	return {}
end

function PatientHistoryRepository:delete(history)
	-- TODO(ORM): Manually remove every patientHistoriesMedications row whose
	-- patientHistory_id equals history.id, save, then remove history and save.
	return nil, 'ORM patient-history deletion is not implemented.'
end

return PatientHistoryRepository
