local BaseRepository = require 'repositories.base_repository'

local SpecializationRepository = {}
SpecializationRepository.__index = SpecializationRepository
setmetatable(SpecializationRepository, { __index = BaseRepository })

function SpecializationRepository.new()
	return setmetatable(BaseRepository.new('specializations'), SpecializationRepository)
end

function SpecializationRepository:delete(specialization)
	-- TODO(ORM): Reject deletion while doctors references specialization.id;
	-- otherwise remove it and call saveChanges().
	return nil, 'ORM specialization deletion is not implemented.'
end

return SpecializationRepository
