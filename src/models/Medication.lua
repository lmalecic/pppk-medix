local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Medication = Model("medications", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "name", Types.Text, Constraint.NotNull, Constraint.Unique },
    { "dosage", Types.Text, Constraint.NotNull },
    { "frequency", Types.Text, Constraint.NotNull },
    { "relatedPatientHistories", Relation.hasMany("patientHistoriesMedications", "medication_id") }
})

function Medication:toString()
    return string.format("%s | %s | %s", self.name or '-', self.dosage or '-', self.frequency or '-')
end
Medication.__tostring = Medication.toString

return Medication
