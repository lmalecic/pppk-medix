local EntityView = {}
EntityView.__index = EntityView

function EntityView.new(options)
	assert(options.key, 'EntityView requires a key')
	assert(options.title, 'EntityView requires a title')
	options.fields = options.fields or {}
	options.defaults = options.defaults or {}
	options.actions = options.actions or {}
	options.mutable = options.mutable ~= false
	return setmetatable(options, EntityView)
end

function EntityView:summary(entity)
	if self.summaryText then return self.summaryText(entity) end
	return self.title .. ' #' .. tostring(entity.id or '?')
end

function EntityView:detailLines(entity)
	if self.detailsText then return self.detailsText(entity) end
	return {}
end

function EntityView:fieldValue(entity, field)
	local value = entity and entity[field.key]
	if field.format then return field.format(value, entity) end
	return value == nil and '' or tostring(value)
end

function EntityView:allActions()
	local actions = {}
	if self.mutable then
		table.insert(actions, { label = 'Edit', type = 'edit' })
		table.insert(actions, { label = 'Delete', type = 'delete' })
	end
	for _, action in ipairs(self.actions) do table.insert(actions, action) end
	return actions
end

return EntityView
