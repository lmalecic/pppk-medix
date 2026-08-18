local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Appointment = Model("appointments", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "scheduledAt", Types.TimestampTz, Constraint.NotNull },

    { "procedure", Relation.belongsTo("procedures", "id"), Constraint.NotNull },
    { "patient", Relation.belongsTo("patients", "id"), Constraint.NotNull },
    { "specialist", Relation.belongsTo("doctors", "id"), Constraint.NotNull },
})

return Appointment
