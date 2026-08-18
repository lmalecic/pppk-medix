return {
	patients = require('repositories.patient_repository').new(),
	patient_histories = require('repositories.patient_history_repository').new(),
	prescriptions = require('repositories.prescription_repository').new(),
	medications = require('repositories.medication_repository').new(),
	appointments = require('repositories.appointment_repository').new(),
	doctors = require('repositories.doctor_repository').new(),
	procedures = require('repositories.procedure_repository').new(),
	specializations = require('repositories.specialization_repository').new(),
}
