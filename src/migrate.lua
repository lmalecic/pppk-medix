package.path = "src/?.lua;src/?/init.lua;" .. package.path
package.cpath = package.cpath .. ";/usr/local/lib/lua/5.1/?.dylib"

local db = require("context")
db:migrateUp()
