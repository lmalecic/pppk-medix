local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local PatientHistoryMedication = Model("patientHistoriesMedications", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "medication", Relation.belongsTo("medications", "id"), Constraint.NotNull },
    { "patientHistory", Relation.belongsTo("patientHistories", "id"), Constraint.NotNull },
})

function PatientHistoryMedication:toString()
    return self.medication and tostring(self.medication) or ('Medication #' .. tostring(self.medication_id or '?'))
end
PatientHistoryMedication.__tostring = PatientHistoryMedication.toString

return PatientHistoryMedication
