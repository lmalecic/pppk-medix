local BaseRepository = {}
BaseRepository.__index = BaseRepository

function BaseRepository.new(entityName)
	return setmetatable({ entityName = entityName }, BaseRepository)
end

function BaseRepository:list(scope)
	-- TODO(ORM): Query self.entityName through context.lua. Apply scope.method/scope.id
	-- when this screen was opened from a related entity.
	return {}
end

function BaseRepository:create(values)
	-- TODO(ORM): Construct the matching model, add it to the DbContext DataSet,
	-- call saveChanges(), and return the materialized entity.
	return nil, 'ORM create is not implemented for ' .. self.entityName .. '.'
end

function BaseRepository:update(entity, values)
	-- TODO(ORM): Assign editable values to the tracked entity, call saveChanges(),
	-- and return the updated entity.
	return nil, 'ORM update is not implemented for ' .. self.entityName .. '.'
end

function BaseRepository:delete(entity)
	-- TODO(ORM): Perform reference checks, mark the entity as deleted, call
	-- saveChanges(), and return true.
	return nil, 'ORM delete is not implemented for ' .. self.entityName .. '.'
end

return BaseRepository
