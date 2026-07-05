package = "medix"
version = "dev-1"

source = {
  url = "local"
}

description = {
  summary = "Simple medical system in TUI with CRUD operations",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "lua-orm",
}

build = {
  type = "builtin",
  modules = {
  	["medix"] = "src/entrypoint.lua",
  }
}
