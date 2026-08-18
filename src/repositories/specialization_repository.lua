local BaseRepository = require 'repositories.base_repository'
local Specialization = require 'models.Specialization'

local SpecializationRepository = {}
SpecializationRepository.__index = SpecializationRepository
setmetatable(SpecializationRepository, { __index = BaseRepository })

function SpecializationRepository.new()
	return setmetatable(BaseRepository.new('specializations', Specialization, {
		orderBy = { 'name' }, searchFields = { 'name' },
	}), SpecializationRepository)
end

function SpecializationRepository:delete(specialization)
	if self:hasReference('doctors', 'specialization_id', specialization.id) then
		return nil, 'The specialization cannot be deleted while doctors exist for this specialization.'
	end
	return BaseRepository.delete(self, specialization)
end

return SpecializationRepository
