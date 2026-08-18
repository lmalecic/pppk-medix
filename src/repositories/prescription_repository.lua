local BaseRepository = require 'repositories.base_repository'
local PatientHistoryMedication = require 'models.PatientHistoryMedication'
local db = require 'context'

local PrescriptionRepository = {}
PrescriptionRepository.__index = PrescriptionRepository
setmetatable(PrescriptionRepository, { __index = BaseRepository })

function PrescriptionRepository.new()
	return setmetatable(BaseRepository.new('patientHistoriesMedications', PatientHistoryMedication, {
		includes = { 'medication', 'patientHistory' },
		scopes = { byHistory = 'patientHistory_id', byMedication = 'medication_id' },
	}), PrescriptionRepository)
end

function PrescriptionRepository:extraSearchNodes(proxy, search)
	return self:foreignKeyMatches(proxy, 'medication_id',
		self:matchingIds('medications', { 'name', 'dosage', 'frequency' }, search))
end

function PrescriptionRepository:listByHistory(historyId, search)
	return BaseRepository.list(self, { method = 'byHistory', id = historyId }, search)
end

function PrescriptionRepository:listByMedication(medicationId, search)
	db.data.doctors:include(function(doctor) return doctor.specialization end):all()
	db.data.patientHistories:include(function(history) return history.patient, history.doctor end):all()
	return BaseRepository.list(self, { method = 'byMedication', id = medicationId }, search)
end

function PrescriptionRepository:prescribe(historyId, medication)
	local duplicate = db.data.patientHistoriesMedications:where(function(item)
		return item.patientHistory_id:equals(historyId)
	end):where(function(item)
		return item.medication_id:equals(medication.id)
	end):first()
	if duplicate then return nil, 'This medication is already prescribed for the selected history.' end
	return BaseRepository.create(self, { patientHistory_id = historyId, medication_id = medication.id })
end

function PrescriptionRepository:remove(prescription)
	return BaseRepository.delete(self, prescription)
end

function PrescriptionRepository:list(scope)
	if scope and scope.historyId then
		return self:listByHistory(scope.historyId, scope.search)
	elseif scope and scope.medicationId then
		return self:listByMedication(scope.medicationId, scope.search)
	end
	return {}
end

return PrescriptionRepository
