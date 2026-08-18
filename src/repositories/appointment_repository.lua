local BaseRepository = require 'repositories.base_repository'
local Appointment = require 'models.Appointment'
local db = require 'context'

local AppointmentRepository = {}
AppointmentRepository.__index = AppointmentRepository
setmetatable(AppointmentRepository, { __index = BaseRepository })

function AppointmentRepository.new()
	return setmetatable(BaseRepository.new('appointments', Appointment, {
		includes = { 'patient', 'procedure', 'specialist' }, orderBy = { 'scheduledAt' },
		scopes = { byPatient = 'patient_id', byDoctor = 'specialist_id', byProcedure = 'procedure_id' },
	}), AppointmentRepository)
end

function AppointmentRepository:extraSearchNodes(proxy, search)
	local nodes = self:foreignKeyMatches(proxy, 'patient_id',
		self:matchingIds('patients', { 'firstName', 'lastName', 'oib' }, search))
	for _, node in ipairs(self:foreignKeyMatches(proxy, 'procedure_id',
		self:matchingIds('procedures', { 'name' }, search))) do table.insert(nodes, node) end
	for _, node in ipairs(self:foreignKeyMatches(proxy, 'specialist_id',
		self:matchingIds('doctors', { 'firstName', 'lastName' }, search))) do table.insert(nodes, node) end
	return nodes
end

function AppointmentRepository:list(scope, search)
	db.data.doctors:include(function(doctor) return doctor.specialization end):all()
	return BaseRepository.list(self, scope, search)
end

return AppointmentRepository
