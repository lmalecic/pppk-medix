local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Specialization = Model("specializations", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.BY_DEFAULT) },
    { "name", Types.Text, Constraint.NotNull },
    { "doctors", Relation.hasMany("doctors", "specialization_id") },
})

function Specialization:toString() return self.name or ('Specialization #' .. tostring(self.id or '?')) end
Specialization.__tostring = Specialization.toString

return Specialization
