local BaseRepository = require 'repositories.base_repository'
local Procedure = require 'models.Procedure'

local ProcedureRepository = {}
ProcedureRepository.__index = ProcedureRepository
setmetatable(ProcedureRepository, { __index = BaseRepository })

function ProcedureRepository.new()
	return setmetatable(BaseRepository.new('procedures', Procedure, {
		orderBy = { 'name' }, searchFields = { 'name' },
	}), ProcedureRepository)
end

function ProcedureRepository:delete(procedure)
	if self:hasReference('appointments', 'procedure_id', procedure.id) then
		return nil, 'The procedure cannot be deleted while appointments exist for this procedure.'
	end
	return BaseRepository.delete(self, procedure)
end

return ProcedureRepository
