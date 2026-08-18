local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Procedure = Model("procedures", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "name", Types.Text, Constraint.NotNull,    Constraint.Unique },
    { "relatedAppointments", Relation.hasMany("appointments", "procedure_id") }
})

return Procedure
