package = "lua-orm"
version = "dev-1"

source = {
  url = "git://example.com/lua-orm"
}

description = {
  summary = "Lua ORM project",
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
