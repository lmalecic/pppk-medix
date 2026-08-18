local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Patient = Model("patients", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "firstName", Types.Text, Constraint.NotNull },
    { "lastName", Types.Text, Constraint.NotNull },
    { "oib", Types.Char(11), Constraint.NotNull, Constraint.Unique },
    { "dateOfBirth", Types.Timestamp, Constraint.NotNull },
    { "sex", Types.Char(1), Constraint.NotNull },
    { "permamentAddress", Types.Text, Constraint.NotNull },
    { "secondaryAddress", Types.Text,      Constraint.NotNull },

    { "patientHistory",   Relation.hasMany("patientHistories", "patient_id") },
    { "appointments", Relation.hasMany("appointments", "patient_id") }
})

--- @enum PatientSex
Patient.Sex = {
    M = "M",
    F = "F",
}

return Patient
