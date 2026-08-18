local BaseRepository = require 'repositories.base_repository'

local DoctorRepository = {}
DoctorRepository.__index = DoctorRepository
setmetatable(DoctorRepository, { __index = BaseRepository })

function DoctorRepository.new()
	return setmetatable(BaseRepository.new('doctors'), DoctorRepository)
end

function DoctorRepository:list(scope)
	-- TODO(ORM): Return all doctors, or filter by specialization_id when opened
	-- from the Specializations screen.
	return {}
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
