package.path = 'src/?.lua;src/?/init.lua;mate/src/?.lua;mate/src/?/init.lua;' .. package.path

package.preload['term.unicode'] = function()
	return {
		width = function(value) return #value end,
		pop_grapheme = function(value) return value:sub(1, -2) end,
	}
end

package.preload['term.layout'] = function()
	return {
		horizontal_line = function(left, right, middle, width)
			return left .. string.rep(middle, math.max(0, width - #left - #right)) .. right
		end,
	}
end

package.preload['mate.batch'] = function() return dofile('mate/src/batch.lua') end
package.preload['mate.input'] = function() return dofile('mate/src/input.lua') end
package.preload['mate.components.line_input'] = function() return dofile('mate/src/components/line_input.lua') end
package.preload['mate.box'] = function() return dofile('mate/src/box.lua') end

local ApplicationController = require 'controllers.application_controller'
local views = require 'views'
local DatePicker = require 'components.date_picker'
local DateTime = require 'util.date-time'

local function repository(rows)
	local value = { rows = rows or {}, nextId = 100 }
	function value:list(scope, search) self.lastSearch = search; self.listCount = (self.listCount or 0) + 1; return self.rows end
	function value:create(fields)
		local row = {}; for key, item in pairs(fields) do row[key] = item end
		row.id = self.nextId; self.nextId = self.nextId + 1; table.insert(self.rows, row); return row
	end
	function value:update(row, fields) for key, item in pairs(fields) do row[key] = item end; return row end
	function value:delete(row)
		for index, candidate in ipairs(self.rows) do if candidate == row then table.remove(self.rows, index); return true end end
		return nil, 'Record not found.'
	end
	return value
end

local repositories = {
	patients = repository { { id = 1, firstName = 'Ana', lastName = 'Novak', oib = '12345678901' } },
	patient_histories = repository { { id = 2, patient_id = 1, doctor_id = 3, diagnosis = 'Asthma' } },
	medications = repository { { id = 4, name = 'Example', dosage = '10 mg', frequency = 'Daily' } },
	appointments = repository { { id = 5, patient_id = 1, specialist_id = 3, procedure_id = 6, scheduledAt = '2026-08-18' } },
	doctors = repository { { id = 3, firstName = 'Maja', lastName = 'Kovac', specialization_id = 7 } },
	procedures = repository { { id = 6, name = 'CT' } },
	specializations = repository { { id = 7, name = 'Radiology' } },
	prescriptions = repository {},
}
function repositories.prescriptions:listByHistory() return self.rows end
function repositories.prescriptions:listByMedication() return self.rows end
function repositories.prescriptions:prescribe(historyId, medication)
	local row = { id = 9, patientHistory_id = historyId, medication_id = medication.id, medication = medication }
	table.insert(self.rows, row); return row
end
function repositories.prescriptions:remove(row) return self:delete(row) end

local function key(name)
	return { id = 'key', data = { string = name, code = name, kind = 'press', ctrl = false, alt = false, shift = false } }
end

local application = ApplicationController.new(views, repositories)
local model = application:init()
application:update(model, { id = 'sys:ready', data = { width = 120, height = 40 } })
assert(#model.tabs == 7, 'seven main tabs are registered')

application:update(model, key('down'))
application:update(model, key('enter'))
application:update(model, key('down'))
application:update(model, key('down'))
application:update(model, key('enter'))
assert(#model.overlays == 1, 'patient history opens as an overlay')
assert(model.overlays[1].controller.view.key == 'patient_histories')
assert(model.overlays[1].state.lockedValues.patient_id == 1, 'patient is locked in nested history editor')

application:update(model, key('enter'))
assert(model.overlays[1].state.mode == 'create')
assert(model.overlays[1].state.draft.patient_id == 1)
assert(model.overlays[1].state.draftRelations.patient_id.id == 1, 'fixed patient renders as the related entity')
application:update(model, key('esc'))
application:update(model, key('esc'))
assert(#model.overlays == 0, 'escape returns one overlay level')

local root = model.tabs[1]
application:update(model, key('esc'))
root.state.selected = 1
application:update(model, key('enter'))
root.state.draft.firstName = 'New'
root.state.editIndex = #root.controller.view.fields + 1
application:update(model, key('enter'))
assert(model.message and model.message.kind == 'success', 'successful create opens a message dialog')
application:update(model, key('enter'))
assert(model.message == nil, 'message dialog closes with enter')

local doctorModel = application:init()
doctorModel.activeTab = 5
application:update(doctorModel, { id = 'sys:ready', data = { width = 120, height = 40 } })
application:update(doctorModel, key('enter'))
application:update(doctorModel, key('enter'))
assert(doctorModel.overlays[1].controller.view.key == 'patient_histories')
assert(doctorModel.overlays[1].state.lockedValues.doctor_id == 3, 'doctor is locked in nested history editor')
application:update(doctorModel, key('esc'))
application:update(doctorModel, key('down'))
application:update(doctorModel, key('enter'))
assert(doctorModel.overlays[1].controller.view.key == 'appointments')
assert(doctorModel.overlays[1].state.lockedValues.specialist_id == 3, 'doctor is locked in nested appointment editor')

local historyModel = application:init()
historyModel.activeTab = 2
application:update(historyModel, { id = 'sys:ready', data = { width = 120, height = 40 } })
application:update(historyModel, key('down'))
application:update(historyModel, key('enter'))
application:update(historyModel, key('down'))
application:update(historyModel, key('down'))
application:update(historyModel, key('enter'))
assert(historyModel.overlays[1].kind == 'prescriptions', 'history opens its prescription manager')
application:update(historyModel, key('enter'))
assert(historyModel.overlays[1].state.mode == 'picker', 'prescribe option opens the medication picker')
application:update(historyModel, key('enter'))
assert(historyModel.message and historyModel.message.kind == 'success', 'prescribing opens success feedback')
application:update(historyModel, key('enter'))
application:update(historyModel, key('enter'))
assert(#historyModel.overlays[1].state.pickerRows == 0, 'already prescribed medications are excluded from the picker')

local relationModel = application:init()
relationModel.activeTab = 2
application:update(relationModel, { id = 'sys:ready', data = { width = 120, height = 40 } })
application:update(relationModel, key('down'))
application:update(relationModel, key('enter'))
application:update(relationModel, key('enter'))
application:update(relationModel, key('enter'))
for _, patient in ipairs(relationModel.tabs[2].state.modal.rows) do
	assert(patient.id ~= 1, 'the current relation is excluded from an entity picker')
end

local picker = DatePicker.new(DateTime.new(2026, 1, 1, 0, 0, 0))
picker.selected = 5
picker:update(key('4')); picker:update(key('5'))
picker:update(key('5')); picker:update(key('9'))
assert(picker.value.minute == 45 and picker.value.second == 59, 'date picker accepts direct numeric time input')

local searchModel = application:init()
application:update(searchModel, { id = 'sys:ready', data = { width = 120, height = 40 } })
local searchState = searchModel.tabs[1].state
application:update(searchModel, { id = 'line_input:text_changed', data = { uid = searchState.searchInput.uid, text = 'first' } })
application:update(searchModel, { id = 'sys:tick', data = { now = 0.2 } })
application:update(searchModel, { id = 'line_input:text_changed', data = { uid = searchState.searchInput.uid, text = 'second' } })
application:update(searchModel, { id = 'sys:tick', data = { now = 0.4 } })
assert(repositories.patients.lastSearch == nil, 'a replaced debounce deadline does not run the previous search')
application:update(searchModel, { id = 'sys:tick', data = { now = 0.51 } })
assert(repositories.patients.lastSearch == 'second', 'the latest search reaches the repository after 300 ms')

local refreshModel = application:init()
application:update(refreshModel, { id = 'sys:ready', data = { width = 120, height = 40 } })
local historyLoads = repositories.patient_histories.listCount
application:update(refreshModel, key('right'))
assert(repositories.patient_histories.listCount == historyLoads + 1, 'opening a tab reloads it from its repository')

print('controller_spec: ok')
