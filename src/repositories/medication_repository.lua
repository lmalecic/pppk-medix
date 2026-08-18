local BaseRepository = require 'repositories.base_repository'

local MedicationRepository = {}
MedicationRepository.__index = MedicationRepository
setmetatable(MedicationRepository, { __index = BaseRepository })

function MedicationRepository.new()
	return setmetatable(BaseRepository.new('medications'), MedicationRepository)
end

function MedicationRepository:delete(medication)
	-- TODO(ORM): Reject deletion while any patientHistoriesMedications row
	-- references medication.id; otherwise delete and saveChanges().
	return nil, 'ORM medication deletion is not implemented.'
end

return MedicationRepository
