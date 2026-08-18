local Helpers = {}

function Helpers.text(value)
	if value == nil or value == '' then return '-' end
	return tostring(value)
end

function Helpers.person(entity)
	return Helpers.text(entity.firstName) .. ' ' .. Helpers.text(entity.lastName)
end

function Helpers.relation(entity, relationName, fallbackField, formatter)
	local ok, related = pcall(function() return entity[relationName] end)
	if ok and related then
		return formatter and formatter(related) or tostring(related.id or related)
	end
	local fallback = entity[fallbackField]
	return '#' .. Helpers.text(fallback)
end

return Helpers
