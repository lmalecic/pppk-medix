local BaseRepository = require 'repositories.base_repository'

local PrescriptionRepository = {}
PrescriptionRepository.__index = PrescriptionRepository
setmetatable(PrescriptionRepository, { __index = BaseRepository })

function PrescriptionRepository.new()
	return setmetatable(BaseRepository.new('patientHistoriesMedications'), PrescriptionRepository)
end

function PrescriptionRepository:listByHistory(historyId)
	-- TODO(ORM): Query patientHistoriesMedications by patientHistory_id and
	-- include medication so the dialog can show name, dosage, and frequency.
	return {}
end

function PrescriptionRepository:listByMedication(medicationId)
	-- TODO(ORM): Query patientHistoriesMedications by medication_id and include
	-- patientHistory (plus its patient and doctor) for the read-only drill-down.
	return {}
end

function PrescriptionRepository:prescribe(historyId, medication)
	-- TODO(ORM): Reject duplicates, create PatientHistoryMedication using the
	-- supplied history and medication, add it, and call saveChanges().
	return nil, 'ORM prescribing is not implemented.'
end

function PrescriptionRepository:remove(prescription)
	-- TODO(ORM): Remove the association only (never the Medication), then save.
	return nil, 'ORM prescription removal is not implemented.'
end

function PrescriptionRepository:list(scope)
	if scope and scope.historyId then
		return self:listByHistory(scope.historyId)
	elseif scope and scope.medicationId then
		return self:listByMedication(scope.medicationId)
	end
	return {}
end

return PrescriptionRepository
