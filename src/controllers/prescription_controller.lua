local Batch = require 'mate.batch'
local LineInput = require 'mate.components.line_input'
local input = require 'mate.input'

local PrescriptionController = {}
PrescriptionController.__index = PrescriptionController

local function pressed(msg, ...)
	for i = 1, select('#', ...) do if input.pressed(msg, select(i, ...)) then return true end end
	return false
end

local function safe(repository, method, ...)
	local ok, value, err = pcall(repository[method], repository, ...)
	if not ok then return nil, tostring(value) end
	return value, err
end

local function medicationOf(prescription)
	local ok, medication = pcall(function() return prescription.medication end)
	if ok and medication then return medication end
	return prescription
end

function PrescriptionController.new(repository)
	return setmetatable({ repository = repository, kind = 'prescriptions' }, PrescriptionController)
end

function PrescriptionController:init(scope)
	local search = LineInput.init(); search.placeholder = 'Search prescriptions...'
	local pickerSearch = LineInput.init(); pickerSearch.placeholder = 'Search medications...'
	local rows, err
	if scope.history then rows, err = safe(self.repository, 'listByHistory', scope.history.id)
	else rows, err = safe(self.repository, 'listByMedication', scope.medication.id) end
	local state = {
		scope = scope, rows = rows or {}, filtered = rows or {}, selected = 1,
		filter = '', searchInput = search, pickerInput = pickerSearch,
		mode = 'list', pickerRows = {}, pickerAllRows = {}, pickerSelected = 1,
		now = 0, pendingSearch = nil,
		prescribedMedicationIds = {},
	}
	if scope.history then
		for _, prescription in ipairs(rows or {}) do state.prescribedMedicationIds[prescription.medication_id] = true end
	end
	return state, Batch(search.msg.enable), err
end

function PrescriptionController:deactivate(state)
	state.searchInput.enabled, state.pickerInput.enabled = false, false
	return Batch(state.searchInput.msg.disable, state.pickerInput.msg.disable)
end

function PrescriptionController:activate(state)
	state.searchInput.enabled, state.pickerInput.enabled = true, false
	return Batch(state.searchInput.msg.enable, state.pickerInput.msg.disable)
end

function PrescriptionController:rowCount(state)
	return #state.filtered + (state.scope.history and 1 or 0)
end

function PrescriptionController:rowAt(state, index)
	if state.scope.history then
		if index == 1 then return { prescribe = true } end
		return state.filtered[index - 1]
	end
	return state.filtered[index]
end

function PrescriptionController:label(row, state)
	if state and state.scope.medication then
		local ok, history = pcall(function() return row.patientHistory end)
		return ok and history and tostring(history) or ('Patient history #' .. tostring(row.patientHistory_id or '?'))
	end
	local medication = medicationOf(row)
	return tostring(medication.name or ('Medication #' .. tostring(row.medication_id or '?')))
		.. ' | ' .. tostring(medication.dosage or '-') .. ' | ' .. tostring(medication.frequency or '-')
end

function PrescriptionController:clamp(state)
	local count = self:rowCount(state)
	if count < 1 then state.selected = 1 else state.selected = math.max(1, math.min(count, state.selected)) end
end

function PrescriptionController:filter(state)
	state.filtered = state.rows
	self:clamp(state)
end

function PrescriptionController:reload(state)
	local rows, err
	if state.scope.history then rows, err = safe(self.repository, 'listByHistory', state.scope.history.id, state.filter)
	else rows, err = safe(self.repository, 'listByMedication', state.scope.medication.id, state.filter) end
	if not rows then return nil, err end
	state.rows = rows; self:filter(state); return true
end

function PrescriptionController:message(kind, text)
	return { type = 'message', message = { kind = kind, title = kind == 'error' and 'Operation failed' or 'Success', text = text } }
end

function PrescriptionController:availableMedications(state, rows)
	local prescribed, available = state.prescribedMedicationIds or {}, {}
	for _, medication in ipairs(rows or {}) do
		if not prescribed[medication.id] then table.insert(available, medication) end
	end
	return available
end

function PrescriptionController:refreshPrescribedMedicationIds(state)
	if not state.scope.history then return true end
	local rows, err = safe(self.repository, 'listByHistory', state.scope.history.id, '')
	if not rows then return nil, err end
	state.prescribedMedicationIds = {}
	for _, prescription in ipairs(rows) do state.prescribedMedicationIds[prescription.medication_id] = true end
	return true
end

function PrescriptionController:openPicker(state, context, batch)
	local loaded, loadErr = self:refreshPrescribedMedicationIds(state)
	if not loaded then return self:message('error', loadErr) end
	local rows, err = context:list('medications', '')
	if not rows then return self:message('error', err) end
	rows = self:availableMedications(state, rows)
	state.mode, state.pickerAllRows, state.pickerRows, state.pickerSelected = 'picker', rows, rows, 1
	state.pickerInput.text = ''
	state.searchInput.enabled, state.pickerInput.enabled = false, true
	batch.push(state.searchInput.msg.disable); batch.push(state.pickerInput.msg.enable)
end

function PrescriptionController:queueSearch(state, kind, text)
	state.pendingSearch = { kind = kind, text = text or '', deadline = state.now + 0.3 }
end

function PrescriptionController:runSearch(state, context)
	local pending = state.pendingSearch
	state.pendingSearch = nil
	if pending.kind == 'picker' then
		local rows, err = context:list('medications', pending.text)
		if not rows then return nil, err end
		state.pickerRows, state.pickerSelected = self:availableMedications(state, rows), 1
		return true
	end
	state.filter = pending.text
	return self:reload(state)
end

function PrescriptionController:update(state, msg, context)
	local batch, cmd = Batch(), nil
	state.searchInput, cmd = LineInput.update(state.searchInput, msg); batch.push(cmd)
	state.pickerInput, cmd = LineInput.update(state.pickerInput, msg); batch.push(cmd)
	if msg.id == 'sys:tick' then
		state.now = msg.data.now
		if state.pendingSearch and state.now >= state.pendingSearch.deadline then
			local ok, err = self:runSearch(state, context)
			if not ok then return state, batch, self:message('error', err) end
		end
	end
	if state.mode == 'picker' then
		if pressed(msg, 'esc', 'escape') then
			state.mode = 'list'; state.pendingSearch = nil; state.pickerInput.enabled, state.searchInput.enabled = false, true
			batch.push(state.pickerInput.msg.disable); batch.push(state.searchInput.msg.enable)
		elseif pressed(msg, 'up', 'k') then state.pickerSelected = math.max(1, state.pickerSelected - 1)
		elseif pressed(msg, 'down', 'j') then state.pickerSelected = math.min(math.max(1, #state.pickerRows), state.pickerSelected + 1)
		elseif pressed(msg, 'enter', 'return') then
			local medication = state.pickerRows[state.pickerSelected]
			if medication then
				local result, err = safe(self.repository, 'prescribe', state.scope.history.id, medication)
				if not result then return state, batch, self:message('error', err or 'Prescription was rejected.') end
				self:reload(state); state.mode = 'list'; state.pickerInput.enabled, state.searchInput.enabled = false, true
				batch.push(state.pickerInput.msg.disable); batch.push(state.searchInput.msg.enable)
				return state, batch, self:message('success', 'Medication successfully prescribed.')
			end
		elseif msg.id == 'line_input:text_changed' and msg.data.uid == state.pickerInput.uid then
			state.pickerSelected = 1; self:queueSearch(state, 'picker', msg.data.text)
		end
		return state, batch
	end
	if pressed(msg, 'esc', 'escape') then return state, batch, { type = 'close_overlay' }
	elseif pressed(msg, 'up', 'k') then state.selected = state.selected - 1; self:clamp(state)
	elseif pressed(msg, 'down', 'j') then state.selected = state.selected + 1; self:clamp(state)
	elseif pressed(msg, 'enter', 'return') then
		local row = self:rowAt(state, state.selected)
		if row and rawget(row, 'prescribe') then
			local intent = self:openPicker(state, context, batch)
			if intent then return state, batch, intent end
		elseif row and state.scope.history then
			local ok, err = safe(self.repository, 'remove', row)
			if not ok then return state, batch, self:message('error', err or 'Removal was rejected.') end
			self:reload(state)
			return state, batch, self:message('success', 'Prescription successfully removed.')
		end
	elseif input.pressed(msg, 'ctrl+l') then
		state.filter = ''; batch.push(state.searchInput.msg.clear); self:queueSearch(state, 'records', '')
	elseif msg.id == 'line_input:text_changed' and msg.data.uid == state.searchInput.uid then
		state.selected = 1; self:queueSearch(state, 'records', msg.data.text)
	end
	return state, batch
end

return PrescriptionController
