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

function EntityView:bindModel(modelClass)
	self.modelClass = modelClass
	for _, field in ipairs(self.fields) do
		field.modelField = modelClass and modelClass.fieldsByName[field.key] or nil
		if modelClass then
			for _, relation in pairs(modelClass.relations) do
				if relation.sourceColumn == field.key and relation.foreignKeyField then
					field.modelRelation = relation
					field.relation = field.relation or relation.referenceTable
				end
			end
		end
		local typeName = field.modelField and field.modelField.type.typeName
		field.dateTime = typeName == 'Timestamp' or typeName == 'TimestampTz'
	end
end

function EntityView:summary(entity)
	if self.summaryText then return self.summaryText(entity) end
	return tostring(entity)
end

function EntityView:detailLines(entity)
	if self.detailsText then return self.detailsText(entity) end
	return {}
end

function EntityView:fieldValue(entity, field, related)
	if related then return tostring(related) end
	if entity and field.modelRelation then
		local ok, value = pcall(function() return entity[field.modelRelation.name] end)
		if ok and value then return tostring(value) end
	end
	local value = entity and entity[field.key]
	if field.format then return field.format(value, entity) end
	return value == nil and '' or tostring(value)
end

function EntityView:placeholder(field)
	local metadata = field.modelField
	if not metadata then return nil end
	if metadata.default ~= nil then
		if type(metadata.default) == 'table' and metadata.default.format then return metadata.default:format() end
		return tostring(metadata.default)
	end
	if not metadata.nullable then return 'required' end
	return nil
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
