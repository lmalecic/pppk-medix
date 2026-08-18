local BaseRepository = require 'repositories.base_repository'
local Doctor = require 'models.Doctor'

local DoctorRepository = {}
DoctorRepository.__index = DoctorRepository
setmetatable(DoctorRepository, { __index = BaseRepository })

function DoctorRepository.new()
	return setmetatable(BaseRepository.new('doctors', Doctor, {
		includes = { 'specialization' }, orderBy = { 'lastName', 'firstName' },
		searchFields = { 'firstName', 'lastName' }, scopes = { bySpecialization = 'specialization_id' },
	}), DoctorRepository)
end

function DoctorRepository:extraSearchNodes(proxy, search)
	return self:foreignKeyMatches(proxy, 'specialization_id', self:matchingIds('specializations', { 'name' }, search))
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
