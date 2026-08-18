local BaseRepository = require 'repositories.base_repository'

local AppointmentRepository = {}
AppointmentRepository.__index = AppointmentRepository
setmetatable(AppointmentRepository, { __index = BaseRepository })

function AppointmentRepository.new()
	return setmetatable(BaseRepository.new('appointments'), AppointmentRepository)
end

function AppointmentRepository:list(scope)
	-- TODO(ORM): Return all appointments, or filter by patient_id,
	-- specialist_id, or procedure_id according to scope.method and scope.id.
	return {}
end

return AppointmentRepository
