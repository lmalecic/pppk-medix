local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local Migration = {}
Migration.version = "20260818174414_fix_patient_column_name_typo_and_add_default_to_patienthistories_fromdate"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
	migrationBuilder:alterTable("patientHistories", {
		Alter.setColumnDefault("fromDate", CurrentTimestamp())
	})

	migrationBuilder:alterTable("patients", {
		Alter.renameColumn("permamentAddress", "permanentAddress")
	})
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)
	migrationBuilder:alterTable("patientHistories", {
		Alter.dropColumnDefault("fromDate")
	})

	migrationBuilder:alterTable("patients", {
		Alter.renameColumn("permanentAddress", "permamentAddress")
	})
end

return Migration
