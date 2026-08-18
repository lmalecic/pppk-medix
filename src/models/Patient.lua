local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")
local DateTime = require("util.date-time")

local Patient = Model("patients", {
    { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS) },
    { "firstName", Types.Text, Constraint.NotNull },
    { "lastName", Types.Text, Constraint.NotNull },
    { "oib", Types.Char(11), Constraint.NotNull, Constraint.Unique },
    { "dateOfBirth", Types.Timestamp, Constraint.NotNull },
    { "sex", Types.Char(1), Constraint.NotNull },
    { "permanentAddress", Types.Text, Constraint.NotNull },
    { "secondaryAddress", Types.Text,      Constraint.NotNull },

    { "patientHistory",   Relation.hasMany("patientHistories", "patient_id") },
    { "appointments", Relation.hasMany("appointments", "patient_id") }
})

--- @enum PatientSex
Patient.Sex = {
    M = "M",
    F = "F",
}

--- @return string
function Patient:getSummary()
    return string.format("%s %s | OIB %s | %s", self.firstName, self.lastName, self.oib, tostring(self.dateOfBirth))
end

--- @return string[]
function Patient:getDetails()
    return {
        "Sex: " .. self.sex,
        "Permanent Address: " .. self.permanentAddress,
        "Secondary Address: " .. self.secondaryAddress,
    }
end

function Patient:toString() return string.format("%s %s | OIB %s", self.firstName or '-', self.lastName or '-', self.oib or '-') end
Patient.__tostring = Patient.toString

return Patient
