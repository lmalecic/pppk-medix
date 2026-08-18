local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local Migration = {}
Migration.version = "20260818054351_change_specializations_and_doctors_identity_modes"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
	migrationBuilder:alterTable("doctors", {
		Alter.setColumnIdentity("id", Constraint.IdentityMode.BY_DEFAULT)
	})

	migrationBuilder:alterTable("specializations", {
		Alter.setColumnIdentity("id", Constraint.IdentityMode.BY_DEFAULT)
	})
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)
	migrationBuilder:alterTable("doctors", {
		Alter.setColumnIdentity("id", Constraint.IdentityMode.ALWAYS)
	})

	migrationBuilder:alterTable("specializations", {
		Alter.setColumnIdentity("id", Constraint.IdentityMode.ALWAYS)
	})
end

return Migration
