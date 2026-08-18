local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local PatientHistory = Model("patientHistories", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "diagnosis", Types.Text },
    { "fromDate", Types.Timestamp, Constraint.NotNull, Constraint.Default(CurrentTimestamp()) },
    { "toDate", Types.Timestamp },
    { "patient", Relation.belongsTo("patients", "id"), Constraint.NotNull },
    { "doctor", Relation.belongsTo("doctors", "id"), Constraint.NotNull },
    { "medications", Relation.hasMany("patientHistoriesMedications", "patientHistory_id") },
})

return PatientHistory
