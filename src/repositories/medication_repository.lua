local BaseRepository = require 'repositories.base_repository'
local Medication = require 'models.Medication'

local MedicationRepository = {}
MedicationRepository.__index = MedicationRepository
setmetatable(MedicationRepository, { __index = BaseRepository })

function MedicationRepository.new()
	return setmetatable(BaseRepository.new('medications', Medication, {
		orderBy = { 'name' }, searchFields = { 'name', 'dosage', 'frequency' },
	}), MedicationRepository)
end

function MedicationRepository:delete(medication)
	if self:hasReference('patientHistoriesMedications', 'medication_id', medication.id) then
		return nil, 'The medication cannot be deleted while prescriptions exist for this medication.'
	end
	return BaseRepository.delete(self, medication)
end

return MedicationRepository
