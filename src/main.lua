package.path = 'src/?.lua;src/?/init.lua;' .. package.path

require("populateData")
require("application")
