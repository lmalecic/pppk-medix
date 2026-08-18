local BaseRepository = require 'repositories.base_repository'
local Patient = require 'models.Patient'

local PatientRepository = {}
PatientRepository.__index = PatientRepository
setmetatable(PatientRepository, { __index = BaseRepository })

function PatientRepository.new()
	return setmetatable(BaseRepository.new('patients', Patient, {
		orderBy = { 'lastName', 'firstName' },
		searchFields = { 'firstName', 'lastName', 'oib', 'permanentAddress', 'secondaryAddress' },
	}), PatientRepository)
end

function PatientRepository:delete(patient)
	if self:hasReference('patientHistories', 'patient_id', patient.id) then
		return nil, 'The patient cannot be deleted while medical-history records exist for this patient.'
	end
	if self:hasReference('appointments', 'patient_id', patient.id) then
		return nil, 'The patient cannot be deleted while appointments exist for this patient.'
	end
	return BaseRepository.delete(self, patient)
end

return PatientRepository
