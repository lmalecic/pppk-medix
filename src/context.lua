local DbContext = require("orm.context")
local lfs = require("lfs")

--- @type DbConfig
local config = {
    host = os.getenv("PGHOST") or "127.0.0.1",
    port = tonumber(os.getenv("PGPORT")) or 5432,
    database = os.getenv("PGDATABASE") or "medix",
    user = os.getenv("PGUSER") or "medix",
    password = os.getenv("PGPASSWORD") or "medix",
    autoMigrate = false,
    migrationsDir = "src/migrations",
}

local schema = {}

for file in lfs.dir("src/models") do
    if file:match("%.lua$") then
        local moduleName = file:sub(1, -5)
        table.insert(schema, require("models." .. moduleName))
    end
end

local db = DbContext.new(config, schema)
local DateTime = require("util.date-time")

-- pgmoon returns Timestamp/TimestampTz columns as DateTime values throughout the app.
local function deserializeDateTime(_, value) return DateTime.fromString(value) end
db.connection.client:set_type_deserializer(1114, "timestamp", deserializeDateTime)
db.connection.client:set_type_deserializer(1184, "timestamptz", deserializeDateTime)

return db
