local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local Migration = {}
Migration.version = "20260818050224_add_patienthistorymedication_and_fix_medications"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
	migrationBuilder:createTable("patientHistoriesMedications", {
		{ "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "patientHistory_id", Types.Int, Constraint.ForeignKey("patientHistories", "id"), Constraint.NotNull },
		{ "medication_id", Types.Int, Constraint.ForeignKey("medications", "id"), Constraint.NotNull }
	})
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)
	migrationBuilder:dropTable("patientHistoriesMedications")
end

return Migration
