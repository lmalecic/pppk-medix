local db = require 'context'
local Specification = require 'orm.query.specification'

local BaseRepository = {}
BaseRepository.__index = BaseRepository

local function packedOr(nodes)
	if #nodes == 0 then return nil end
	if #nodes == 1 then return nodes[1] end
	return Specification.or_(unpack(nodes))
end

function BaseRepository.new(entityName, modelClass, options)
	assert(modelClass and type(modelClass.new) == 'function', 'BaseRepository requires a model class')
	options = options or {}
	return setmetatable({ entityName = entityName, modelClass = modelClass,
		includes = options.includes or {}, orderBy = options.orderBy or {},
		searchFields = options.searchFields or {}, scopes = options.scopes or {} }, BaseRepository)
end

function BaseRepository:searchNode(proxy, search)
	if not search or search == '' then return nil end
	local nodes, pattern = {}, '%' .. search .. '%'
	for _, fieldName in ipairs(self.searchFields) do table.insert(nodes, proxy[fieldName]:ilike(pattern)) end
	if self.extraSearchNodes then
		for _, node in ipairs(self:extraSearchNodes(proxy, search) or {}) do table.insert(nodes, node) end
	end
	return packedOr(nodes)
end

function BaseRepository:matchingIds(entityName, fields, search)
	local query = db.data[entityName]:where(function(entity)
		local nodes = {}
		for _, name in ipairs(fields) do table.insert(nodes, entity[name]:ilike('%' .. search .. '%')) end
		return packedOr(nodes)
	end)
	local ids = {}
	for _, entity in ipairs(query:all()) do table.insert(ids, entity.id) end
	return ids
end

function BaseRepository:foreignKeyMatches(proxy, fieldName, ids)
	local nodes = {}
	for _, id in ipairs(ids) do table.insert(nodes, proxy[fieldName]:equals(id)) end
	return nodes
end

function BaseRepository:list(scope, search)
	local query = db.data[self.entityName]
	if #self.includes > 0 then
		local includes = self.includes
		query = query:include(function(entity)
			local result = {}
			for _, name in ipairs(includes) do table.insert(result, entity[name]) end
			return unpack(result)
		end)
	end
	if scope and scope.method then
		local fieldName = self.scopes[scope.method]
		assert(fieldName, 'Unsupported ' .. self.entityName .. ' scope: ' .. tostring(scope.method))
		query = query:where(function(entity) return entity[fieldName]:equals(scope.id) end)
	end
	if search and search ~= '' then
		query = query:where(function(entity)
			return self:searchNode(entity, search) or entity[self.modelClass.primaryKey]:equals(-1)
		end)
	end
	if #self.orderBy > 0 then
		local fields = self.orderBy
		query = query:orderBy(function(entity)
			local result = {}
			for _, name in ipairs(fields) do table.insert(result, entity[name]:asc()) end
			return unpack(result)
		end)
	end
	return query:all()
end

function BaseRepository:normalizedValues(values)
	local result = {}
	for _, field in ipairs(self.modelClass.fields) do
		if not field.autoIncrement and values[field.name] ~= '' then result[field.name] = values[field.name] end
	end
	return result
end

function BaseRepository:validate(values)
	for _, field in ipairs(self.modelClass.fields) do
		if not field.autoIncrement and not field.nullable and field.default == nil
			and (values[field.name] == nil or values[field.name] == '') then
			return nil, field.name .. ' is required.'
		end
	end
	return true
end

function BaseRepository:create(values)
	local normalized = self:normalizedValues(values)
	local valid, err = self:validate(normalized)
	if not valid then return nil, err end
	local entity = self.modelClass.new(normalized)
	db.data[self.entityName]:add(entity)
	db:saveChanges()
	return entity
end

function BaseRepository:update(entity, values)
	local normalized = self:normalizedValues(values)
	local valid, err = self:validate(normalized)
	if not valid then return nil, err end
	for _, field in ipairs(self.modelClass.fields) do
		if not field.primaryKey and not field.autoIncrement then entity[field.name] = normalized[field.name] end
	end
	db:saveChanges()
	return entity
end

function BaseRepository:delete(entity)
	db.data[self.entityName]:remove(entity)
	db:saveChanges()
	return true
end

function BaseRepository:hasReference(entityName, fieldName, id)
	return db.data[entityName]:where(function(entity) return entity[fieldName]:equals(id) end):first() ~= nil
end

return BaseRepository
