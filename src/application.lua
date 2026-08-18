local term = require 'term'
require 'dist.out'

local width, height, err = term:get_size()
if not width or not height then
	io.stderr:write('mate requires an interactive terminal.\n')
	io.stderr:write('Run it with: docker compose run --rm app\n')
	if err then io.stderr:write('term:get_size failed: ' .. tostring(err) .. '\n') end
	os.exit(1)
end

local App = require 'mate.app'
local ApplicationController = require 'controllers.application_controller'
local views = require 'views'
local repositories = require 'repositories'

local application = ApplicationController.new(views, repositories)

App {
	config = { fps = 30, log_key = 'f12', term_poll_timeout = 10 },
	init = function() return application:init() end,
	update = function(model, msg) return application:update(model, msg) end,
	view = function(model, buf) application:viewModel(model, buf) end,
}
