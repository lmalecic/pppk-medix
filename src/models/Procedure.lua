local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Procedure = Model("procedures", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "name", Types.Text, Constraint.NotNull,    Constraint.Unique },
    { "relatedAppointments", Relation.hasMany("appointments", "procedure_id") }
})

function Procedure:toString() return self.name or ('Procedure #' .. tostring(self.id or '?')) end
Procedure.__tostring = Procedure.toString

return Procedure
