local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Doctor = Model("doctors", {
    { "id",                       Types.Int,                                        Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.BY_DEFAULT) },
    { "firstName",                Types.Text,                                       Constraint.NotNull },
    { "lastName",                 Types.Text,                                       Constraint.NotNull },

    { "specialization",           Relation.belongsTo("specializations", "id"),      Constraint.NotNull },
    { "assignedPatientHistories", Relation.hasMany("patientHistories", "doctor_id") },
    { "patientAppointments",      Relation.hasMany("appointments", "specialist_id") },
})

return Doctor
