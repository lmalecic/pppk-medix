package.path = "src/?.lua;src/?/init.lua;" .. package.path
package.cpath = package.cpath .. ";/usr/local/lib/lua/5.1/?.dylib"

local MigrationGenerator = require("orm.migrations.generator")
local db = require("context")


local params = { ... }
local migrationName = params[1]
assert(migrationName ~= nil, "Please provide a migration name")

local generator = MigrationGenerator.new(migrationName, db)
generator:generate()
