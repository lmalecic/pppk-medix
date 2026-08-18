local Batch = require 'mate.batch'
local input = require 'mate.input'
local EntityController = require 'controllers.entity_controller'
local PrescriptionController = require 'controllers.prescription_controller'
local Layout = require 'controllers.layout'
local Navbar = require 'views.navbar'
local EntityScreen = require 'views.entity_screen'
local PrescriptionsView = require 'views.prescriptions'
local MessageDialog = require 'views.message_dialog'

local ApplicationController = {}
ApplicationController.__index = ApplicationController

local function safeList(repository, scope)
	local ok, rows, err = pcall(repository.list, repository, scope)
	if not ok then return nil, tostring(rows) end
	return rows, err
end

function ApplicationController.new(views, repositories)
	local self = setmetatable({}, ApplicationController)
	self.views, self.repositories = views, repositories
	self.navbar, self.entityScreen = Navbar.new(views), EntityScreen.new()
	self.prescriptionsView, self.messageDialog = PrescriptionsView.new(), MessageDialog.new()
	return self
end

function ApplicationController:view(key) return self.views.byKey[key] end

function ApplicationController:list(key)
	local repository = self.repositories[key]
	if not repository then return nil, 'No repository is registered for ' .. tostring(key) .. '.' end
	return safeList(repository, nil)
end

function ApplicationController:init()
	local model = { ready = false, activeTab = 1, tabs = {}, overlays = {}, message = nil, layout = Layout.new(80, 24) }
	local batch = Batch()
	for index, view in ipairs(self.views) do
		local controller = EntityController.new(view, assert(self.repositories[view.key]))
		local state, initBatch, err = controller:init(nil)
		model.tabs[index] = { kind = 'entity', controller = controller, state = state }
		batch.push(initBatch)
		if index ~= 1 then batch.push(controller:deactivate(state)) end
		if err and not model.message then model.message = { kind = 'error', title = 'Loading failed', text = err } end
	end
	return model, batch
end

function ApplicationController:top(model) return model.overlays[#model.overlays] or model.tabs[model.activeTab] end

function ApplicationController:switchTab(model, direction, batch)
	local nextTab = model.activeTab + direction
	if nextTab < 1 or nextTab > #model.tabs then return end
	local current = model.tabs[model.activeTab]
	batch.push(current.controller:deactivate(current.state))
	model.activeTab = nextTab
	local target = model.tabs[nextTab]
	batch.push(target.controller:activate(target.state))
end

function ApplicationController:pushEntity(model, intent, batch)
	local current = self:top(model)
	batch.push(current.controller:deactivate(current.state))
	local view = assert(self.views.byKey[intent.target])
	local controller = EntityController.new(view, assert(self.repositories[intent.target]))
	local state, initBatch, err = controller:init(intent.scope)
	batch.push(initBatch)
	table.insert(model.overlays, { kind = 'entity', controller = controller, state = state })
	if err then model.message = { kind = 'error', title = 'Loading failed', text = err } end
end

function ApplicationController:pushPrescriptions(model, intent, batch)
	local current = self:top(model)
	batch.push(current.controller:deactivate(current.state))
	local controller = PrescriptionController.new(self.repositories.prescriptions)
	local scope = intent.history and { history = intent.history } or { medication = intent.medication }
	local state, initBatch, err = controller:init(scope)
	batch.push(initBatch)
	table.insert(model.overlays, { kind = 'prescriptions', controller = controller, state = state })
	if err then model.message = { kind = 'error', title = 'Loading failed', text = err } end
end

function ApplicationController:popOverlay(model, batch)
	if #model.overlays == 0 then return end
	local current = table.remove(model.overlays)
	batch.push(current.controller:deactivate(current.state))
	local target = self:top(model)
	batch.push(target.controller:activate(target.state))
end

function ApplicationController:handleIntent(model, intent, batch)
	if not intent then return end
	if intent.type == 'message' then model.message = intent.message
	elseif intent.type == 'open_entity' then self:pushEntity(model, intent, batch)
	elseif intent.type == 'manage_prescriptions' or intent.type == 'open_prescriptions' then self:pushPrescriptions(model, intent, batch)
	elseif intent.type == 'close_overlay' then self:popOverlay(model, batch) end
end

function ApplicationController:update(model, msg)
	local batch = Batch()
	if msg.id == 'sys:ready' then
		model.ready = true; model.layout:resize(msg.data.width, msg.data.height); return model, batch
	elseif msg.id == 'sys:resize' then
		model.layout:resize(msg.data.width, msg.data.height); return model, batch
	elseif input.pressed(msg, 'ctrl+c') then
		batch.push({ id = 'quit' }); return model, batch
	end
	if model.message then
		if input.pressed(msg, 'enter') or input.pressed(msg, 'return') or input.pressed(msg, 'esc') or input.pressed(msg, 'escape') then model.message = nil end
		return model, batch
	end
	local top = self:top(model)
	if #model.overlays == 0 and top.state.focus == 'results' then
		if input.pressed(msg, 'left') then self:switchTab(model, -1, batch); return model, batch
		elseif input.pressed(msg, 'right') then self:switchTab(model, 1, batch); return model, batch end
	end
	local state, controllerBatch, intent = top.controller:update(top.state, msg, self)
	top.state = state; batch.push(controllerBatch); self:handleIntent(model, intent, batch)
	return model, batch
end

function ApplicationController:viewModel(model, buf)
	if not model.ready then return end
	self.navbar:view(model, buf)
	local root = model.tabs[model.activeTab]
	self.entityScreen:view(root.controller, root.state, buf, model.layout, false)
	for _, overlay in ipairs(model.overlays) do
		if overlay.kind == 'entity' then self.entityScreen:view(overlay.controller, overlay.state, buf, model.layout, true)
		else self.prescriptionsView:view(overlay.controller, overlay.state, buf, model.layout) end
	end
	self.messageDialog:view(model.message, buf, model.layout)
end

return ApplicationController
