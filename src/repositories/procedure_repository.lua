local BaseRepository = require 'repositories.base_repository'

local ProcedureRepository = {}
ProcedureRepository.__index = ProcedureRepository
setmetatable(ProcedureRepository, { __index = BaseRepository })

function ProcedureRepository.new()
	return setmetatable(BaseRepository.new('procedures'), ProcedureRepository)
end

function ProcedureRepository:delete(procedure)
	-- TODO(ORM): Reject deletion while appointments references procedure.id;
	-- otherwise remove it and call saveChanges().
	return nil, 'ORM procedure deletion is not implemented.'
end

return ProcedureRepository
