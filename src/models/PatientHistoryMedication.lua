local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local PatientHistoryMedication = Model("patientHistoriesMedications", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "medication", Relation.belongsTo("medications", "id"), Constraint.NotNull },
    { "patientHistory", Relation.belongsTo("patientHistories", "id"), Constraint.NotNull },
})

return PatientHistoryMedication
