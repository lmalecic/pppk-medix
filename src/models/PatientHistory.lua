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

function PatientHistory:toString()
    local patient = self.patient and tostring(self.patient) or ('patient #' .. tostring(self.patient_id or '?'))
    local doctor = self.doctor and tostring(self.doctor) or ('doctor #' .. tostring(self.doctor_id or '?'))
    return string.format("%s | %s - %s | %s | %s", self.diagnosis or '-', tostring(self.fromDate or '-'), tostring(self.toDate or '-'), patient, doctor)
end
PatientHistory.__tostring = PatientHistory.toString

return PatientHistory
