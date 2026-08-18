local db = require("context")
local BaseRepository = require 'repositories.base_repository'

local DoctorRepository = {}
DoctorRepository.__index = DoctorRepository
setmetatable(DoctorRepository, { __index = BaseRepository })

function DoctorRepository.new()
	return setmetatable(BaseRepository.new('doctors'), DoctorRepository)
end

function DoctorRepository:list(scope)
    local query = db.data.doctors:include(function(doctor)
        return doctor.specialization
    end):orderBy(function(doctor)
        return doctor.firstName:asc(), doctor.lastName:asc()
    end)

    if scope and scope.method == "bySpecialization" then
        query = query:where(function(doctor)
            return doctor.specialization_id:equals(scope.id)
        end)
    end

    return query:all()
end

function DoctorRepository:create()
	return nil, 'Doctors can only be created during application initialization.'
end

function DoctorRepository:update()
	return nil, 'Doctors are read-only.'
end

function DoctorRepository:delete()
	return nil, 'Doctors cannot be deleted.'
end

return DoctorRepository
