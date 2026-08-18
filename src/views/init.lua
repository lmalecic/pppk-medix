local views = {
	require 'views.patients',
	require 'views.patient_histories',
	require 'views.medications',
	require 'views.appointments',
	require 'views.doctors',
	require 'views.procedures',
	require 'views.specializations',
}

views.byKey = {}
for index, view in ipairs(views) do
	view.index = index
	views.byKey[view.key] = view
end

return views
