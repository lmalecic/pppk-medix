local Doctor = require("models.Doctor")
local Specialization = require("models.Specialization")

local db = require("context")

local Specializations = {
    Cardiology = Specialization.new({ id = 1, name = "Cardiology" }),
    Radiology = Specialization.new({ id = 2, name = "Radiology" }),
    Neurology = Specialization.new({ id = 3, name = "Neurology" }),
    Orthopedics = Specialization.new({ id = 4, name = "Orthopedics" }),
    Pediatrics = Specialization.new({ id = 5, name = "Pediatrics" }),
    Dermatology = Specialization.new({ id = 6, name = "Dermatology" }),
    DoctorOfScience = Specialization.new({ id = 7, name = "dr. sc." })
}

local areChangesMade = false

for _, specialization in pairs(Specializations) do
    if db.data.specializations:find(specialization.id) == nil then
        db.data.specializations:add(specialization)
        areChangesMade = true
    end
end

if areChangesMade then
    areChangesMade = false
    db:saveChanges()
end

local Doctors = {
    Doctor.new({
        id = 1,
        firstName = "Franjo",
        lastName = "Tuđman",
        specialization = Specializations.DoctorOfScience,
    }),

    Doctor.new({
        id = 2,
        firstName = "Dmitar",
        lastName = "Zvonimir",
        specialization = Specializations.Orthopedics,
    }),

    Doctor.new({
        id = 3,
        firstName = "Petar Krešimir IV",
        lastName = "Trpimirović",
        specialization = Specializations.Neurology,
    }),

    Doctor.new({
        id = 4,
        firstName = "Adi",
        lastName = "Dassler",
        specialization = Specializations.Orthopedics,
    }),

    Doctor.new({
        id = 5,
        firstName = "Gabe",
        lastName = "Newell",
        specialization = Specializations.Radiology,
    })
}

for _, doctor in ipairs(Doctors) do
    if db.data.doctors:find(doctor.id) == nil then
        db.data.doctors:add(doctor)
        areChangesMade = true
    end
end

if areChangesMade then
    db:saveChanges()
end
