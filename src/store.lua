local Store = {}

local function copy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = v end
	return c
end

local function contains(haystack, needle)
	if needle == '' then return true end
	return tostring(haystack or ''):lower():find(needle, 1, true) ~= nil
end

local doctors = {
	{ id = 1, ime = 'Maja',  prezime = 'Kovac',  specijalizacija = 'Obiteljska medicina' },
	{ id = 2, ime = 'Ivan',  prezime = 'Horvat', specijalizacija = 'Radiologija' },
	{ id = 3, ime = 'Petra', prezime = 'Maric',  specijalizacija = 'Kardiologija' },
	{ id = 4, ime = 'Luka',  prezime = 'Babic',  specijalizacija = 'Dermatologija' },
	{ id = 5, ime = 'Nina',  prezime = 'Jukic',  specijalizacija = 'Stomatologija' },
}

Store.db = {
	patients = {
		{
			id = 1,
			ime = 'Ana',
			prezime = 'Novak',
			oib = '12345678901',
			datum_rodjenja = '1989-04-17',
			spol = 'Z',
			boraviste = 'Ilica 12, Zagreb',
			prebivaliste = 'Vukovarska 4, Osijek',
		},
		{
			id = 2,
			ime = 'Marko',
			prezime = 'Kralj',
			oib = '98765432109',
			datum_rodjenja = '1978-11-02',
			spol = 'M',
			boraviste = 'Riva 8, Split',
			prebivaliste = 'Riva 8, Split',
		},
	},
	histories = {
		{ id = 1, pacijent_id = 1, stanje = 'Astma',        od = '2018-03-01', do_datuma = '2021-09-15', lijecnik_id = 1 },
		{ id = 2, pacijent_id = 2, stanje = 'Hipertenzija', od = '2022-05-10', do_datuma = 'trenutno',   lijecnik_id = 3 },
	},
	medications = {
		{ id = 1, pacijent_id = 1, stanje = 'Alergijski rinitis', lijek = 'Loratadin', doza = '10 mg', ucestalost = '1x dnevno', lijecnik_id = 1 },
		{ id = 2, pacijent_id = 2, stanje = 'Hipertenzija',       lijek = 'Amlodipin', doza = '5 mg',  ucestalost = '1x dnevno', lijecnik_id = 3 },
	},
	appointments = {
		{ id = 1, pacijent_id = 1, tip = 'MR',  termin = '2026-07-03 09:30', specijalist_id = 2, status = 'zakazano' },
		{ id = 2, pacijent_id = 2, tip = 'EKG', termin = '2026-07-04 13:00', specijalist_id = 3, status = 'zakazano' },
	},
	doctors = doctors,
}

Store.schemas = {
	{
		key = 'patients',
		shortcut = 'p',
		title = 'Pacijenti',
		mutable = true,
		fields = { 'ime', 'prezime', 'oib', 'datum_rodjenja', 'spol', 'boraviste', 'prebivaliste' },
		defaults = {
			ime = 'Novi',
			prezime = 'Pacijent',
			oib = '00000000000',
			datum_rodjenja = '2000-01-01',
			spol = 'N',
			boraviste = 'Nepoznato',
			prebivaliste = 'Nepoznato',
		},
		summary = function(r)
			return r.ime .. ' ' .. r.prezime .. ' | OIB ' .. r.oib .. ' | ' .. r.datum_rodjenja
		end,
		details = function(r)
			return {
				'Spol: ' .. r.spol,
				'Boraviste: ' .. r.boraviste,
				'Prebivaliste: ' .. r.prebivaliste,
			}
		end,
	},
	{
		key = 'histories',
		shortcut = 'b',
		title = 'Povijest bolesti',
		mutable = true,
		fields = { 'pacijent_id', 'stanje', 'od', 'do_datuma', 'lijecnik_id' },
		defaults = { pacijent_id = '1', stanje = 'Novo stanje', od = '2026-06-29', do_datuma = 'trenutno', lijecnik_id = '1' },
		summary = function(r)
			return '#' .. r.pacijent_id .. ' | ' .. r.stanje .. ' | ' .. r.od .. ' - ' .. r.do_datuma
		end,
		details = function(r)
			return { 'Lijecnik ID: ' .. r.lijecnik_id }
		end,
	},
	{
		key = 'medications',
		shortcut = 'l',
		title = 'Lijekovi',
		mutable = true,
		fields = { 'pacijent_id', 'stanje', 'lijek', 'doza', 'ucestalost', 'lijecnik_id' },
		defaults = { pacijent_id = '1', stanje = 'Stanje', lijek = 'Lijek', doza = '1 tableta', ucestalost = '1x dnevno', lijecnik_id = '1' },
		summary = function(r)
			return '#' .. r.pacijent_id .. ' | ' .. r.lijek .. ' | ' .. r.doza .. ' | ' .. r.ucestalost
		end,
		details = function(r)
			return { 'Stanje: ' .. r.stanje, 'Lijecnik ID: ' .. r.lijecnik_id }
		end,
	},
	{
		key = 'appointments',
		shortcut = 't',
		title = 'Specijalisticki pregledi',
		mutable = true,
		fields = { 'pacijent_id', 'tip', 'termin', 'specijalist_id', 'status' },
		defaults = { pacijent_id = '1', tip = 'CT', termin = '2026-07-01 10:00', specijalist_id = '2', status = 'zakazano' },
		summary = function(r)
			return '#' .. r.pacijent_id .. ' | ' .. r.tip .. ' | ' .. r.termin .. ' | spec. ' .. r.specijalist_id
		end,
		details = function(r)
			return { 'Status: ' .. r.status }
		end,
	},
	{
		key = 'doctors',
		shortcut = 'd',
		title = 'Lijecnici',
		mutable = false,
		fields = { 'ime', 'prezime', 'specijalizacija' },
		defaults = {},
		summary = function(r)
			return r.ime .. ' ' .. r.prezime .. ' | ' .. r.specijalizacija
		end,
		details = function()
			return { 'Read-only: definirano pri inicijalizaciji aplikacije.' }
		end,
	},
}

Store.schema_by_key = {}
Store.schema_by_shortcut = {}
for i, schema in ipairs(Store.schemas) do
	schema.index = i
	Store.schema_by_key[schema.key] = schema
	Store.schema_by_shortcut[schema.shortcut] = schema
end

Store.relations = {
	pacijent_id = {
		schema_key = 'patients',
		label = function(row)
			return row.ime .. ' ' .. row.prezime .. ' | OIB ' .. row.oib
		end,
	},
	lijecnik_id = {
		schema_key = 'doctors',
		label = function(row)
			return row.ime .. ' ' .. row.prezime .. ' | ' .. row.specijalizacija
		end,
	},
	specijalist_id = {
		schema_key = 'doctors',
		label = function(row)
			return row.ime .. ' ' .. row.prezime .. ' | ' .. row.specijalizacija
		end,
	},
}

function Store.selected_schema(model)
	return Store.schemas[model.entity]
end

local function next_id(rows)
	local id = 0
	for _, row in ipairs(rows) do
		if tonumber(row.id) and tonumber(row.id) > id then id = tonumber(row.id) end
	end
	return id + 1
end

local function row_text(schema, row)
	local chunks = { schema.summary(row) }
	for _, line in ipairs(schema.details(row)) do table.insert(chunks, line) end
	return table.concat(chunks, ' ')
end

function Store.filtered_rows(model)
	local schema = Store.selected_schema(model)
	local rows = Store.db[schema.key]
	local filtered = {}
	local q = model.filter:lower()

	for index, row in ipairs(rows) do
		if contains(row_text(schema, row), q) then
			table.insert(filtered, { index = index, row = row })
		end
	end

	return filtered
end

function Store.create_row(schema, assignments)
	local row = copy(schema.defaults)
	for _, field in ipairs(schema.fields) do
		if assignments[field] then row[field] = assignments[field] end
	end
	row.id = next_id(Store.db[schema.key])
	table.insert(Store.db[schema.key], row)
	return row
end

function Store.update_row(schema, row, assignments)
	local changed = {}
	for _, field in ipairs(schema.fields) do
		if assignments[field] then
			row[field] = assignments[field]
			table.insert(changed, field)
		end
	end
	return changed
end

function Store.relation_for(field)
	return Store.relations[field]
end

function Store.related_rows(field, query)
	local relation = Store.relation_for(field)
	if not relation then return {} end

	local rows = Store.db[relation.schema_key]
	local q = (query or ''):lower()
	local results = {}

	for _, row in ipairs(rows) do
		local label = relation.label(row)
		if q == '' or label:lower():find(q, 1, true) then
			table.insert(results, { row = row, label = label })
		end
	end

	return results
end

return Store
