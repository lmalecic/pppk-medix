local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local Migration = {}
Migration.version = "20260818044417_initial_migration"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
	migrationBuilder:createTable("specializations", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "name", Types.Text, Constraint.NotNull }
	})

	migrationBuilder:createTable("doctors", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "firstName", Types.Text, Constraint.NotNull },
		{ "lastName", Types.Text, Constraint.NotNull },
		{ "specialization_id", Types.Int, Constraint.ForeignKey("specializations", "id"), Constraint.NotNull }
	})

	migrationBuilder:createTable("patients", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "firstName", Types.Text, Constraint.NotNull },
		{ "lastName", Types.Text, Constraint.NotNull },
		{ "oib", Types.Char(11), Constraint.Unique, Constraint.NotNull },
		{ "dateOfBirth", Types.Timestamp, Constraint.NotNull },
		{ "sex", Types.Char(), Constraint.NotNull },
		{ "permamentAddress", Types.Text, Constraint.NotNull },
		{ "secondaryAddress", Types.Text, Constraint.NotNull }
	})

	migrationBuilder:createTable("procedures", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "name", Types.Text, Constraint.Unique, Constraint.NotNull }
	})

	migrationBuilder:createTable("appointments", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "scheduledAt", Types.TimestampTz, Constraint.NotNull },
		{ "patient_id", Types.Int, Constraint.ForeignKey("patients", "id"), Constraint.NotNull },
		{ "specialist_id", Types.Int, Constraint.ForeignKey("doctors", "id"), Constraint.NotNull },
		{ "procedure_id", Types.Int, Constraint.ForeignKey("procedures", "id"), Constraint.NotNull }
	})

	migrationBuilder:createTable("medications", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "name", Types.Text, Constraint.Unique, Constraint.NotNull },
		{ "dosage", Types.Text, Constraint.NotNull },
		{ "frequency", Types.Text, Constraint.NotNull }
	})

	migrationBuilder:createTable("patientHistories", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "diagnosis", Types.Text },
		{ "fromDate", Types.Timestamp, Constraint.NotNull },
		{ "toDate", Types.Timestamp },
		{ "doctor_id", Types.Int, Constraint.ForeignKey("doctors", "id"), Constraint.NotNull },
		{ "patient_id", Types.Int, Constraint.ForeignKey("patients", "id"), Constraint.NotNull }
	})
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)
	migrationBuilder:dropTable("patientHistories")

	migrationBuilder:dropTable("medications")

	migrationBuilder:dropTable("appointments")

	migrationBuilder:dropTable("procedures")

	migrationBuilder:dropTable("patients")

	migrationBuilder:dropTable("doctors")

	migrationBuilder:dropTable("specializations")
end

return Migration
