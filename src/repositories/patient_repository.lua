local db = require("context")
local Patient = require("models.Patient")

local BaseRepository = require 'repositories.base_repository'

local PatientRepository = {}
PatientRepository.__index = PatientRepository
setmetatable(PatientRepository, { __index = BaseRepository })

function PatientRepository.new()
    return setmetatable(BaseRepository.new('patients'), PatientRepository)
end

function PatientRepository:create(data)
    local patient = Patient.new(data)
    db.data.patients:add(patient)
    db:saveChanges()
    return patient
end

function PatientRepository:removeById(id)
    local patient = db.data.patients:find(id)
    if patient then
        db.data.patients:remove(patient)
        db:saveChanges()
    end
end

function PatientRepository:remove(patient)
    db.data.patients:remove(patient)
    db:saveChanges()
end

function PatientRepository:list(scope)
    return db.data.patients:include(function(patient)
        return patient.patientHistory, patient.appointments
    end):all()
end

function PatientRepository:delete(patient)
	-- TODO(ORM): Reject deletion when patientHistories or appointments contains
	-- a row for patient.id. Otherwise remove the patient and saveChanges().
	return nil, 'ORM patient deletion is not implemented.'
end

return PatientRepository
