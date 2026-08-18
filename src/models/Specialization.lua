local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Specialization = Model("specializations", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "name", Types.Text, Constraint.NotNull },
    { "doctors", Relation.hasMany("doctors", "specializationId"), Constraint.NotNull },
})

return Specialization
