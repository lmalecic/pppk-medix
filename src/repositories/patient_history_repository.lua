local BaseRepository = require 'repositories.base_repository'
local PatientHistory = require 'models.PatientHistory'
local db = require 'context'

local PatientHistoryRepository = {}
PatientHistoryRepository.__index = PatientHistoryRepository
setmetatable(PatientHistoryRepository, { __index = BaseRepository })

function PatientHistoryRepository.new()
	return setmetatable(BaseRepository.new('patientHistories', PatientHistory, {
		includes = { 'patient', 'doctor', 'medications' }, orderBy = { 'fromDate' }, searchFields = { 'diagnosis' },
		scopes = { byPatient = 'patient_id', byDoctor = 'doctor_id' },
	}), PatientHistoryRepository)
end

function PatientHistoryRepository:extraSearchNodes(proxy, search)
	local nodes = self:foreignKeyMatches(proxy, 'patient_id',
		self:matchingIds('patients', { 'firstName', 'lastName', 'oib' }, search))
	for _, node in ipairs(self:foreignKeyMatches(proxy, 'doctor_id',
		self:matchingIds('doctors', { 'firstName', 'lastName' }, search))) do table.insert(nodes, node) end
	return nodes
end

function PatientHistoryRepository:list(scope, search)
	-- Preload the doctor's own relation so every rendered Doctor can use toString().
	db.data.doctors:include(function(doctor) return doctor.specialization end):all()
	-- The ORM supports direct includes only. Preloading the association with its
	-- Medication lets the subsequent history include reuse fully materialized rows.
	db.data.patientHistoriesMedications:include(function(item) return item.medication end):all()
	return BaseRepository.list(self, scope, search)
end

function PatientHistoryRepository:delete(history)
	local prescriptions = db.data.patientHistoriesMedications:where(function(item)
		return item.patientHistory_id:equals(history.id)
	end):all()
	for _, prescription in ipairs(prescriptions) do db.data.patientHistoriesMedications:remove(prescription) end
	-- The ORM has no cascade ordering, so persist dependent removals first.
	if #prescriptions > 0 then db:saveChanges() end
	return BaseRepository.delete(self, history)
end

return PatientHistoryRepository
