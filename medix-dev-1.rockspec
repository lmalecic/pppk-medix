package = "medix"
version = "dev-1"

source = {
  url = "https://github.com/lmalecic/pppk-medix"
}

description = {
  summary = "Simple medical system in TUI with CRUD operations",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "pgmoon",
  "luasocket",
  "luabitop"
}

build = {
  type = "none"
}
