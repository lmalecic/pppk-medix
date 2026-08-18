# MediX
A medical system with CRUD operations in TUI written in lua.

This project was made for my university course *Accessing data from program code*.

## Dependencies
This project uses lua-orm made by the same author to communicate with the database.

## How to run?
In the project root directory, run these Docker commands:
```
docker compose up -d db
docker compose run --rm app
```

## TUI architecture

- `src/application.lua` is the Mate composition root.
- `src/controllers/` owns navigation, CRUD state, nested overlays, and input routing.
- `src/views/` contains the navbar and one editable entity view per tab.
- `src/repositories/` is the persistence boundary. Its methods contain explicit
  `TODO(ORM)` markers for the application-specific ORM queries and mutations.
- `src/components/` contains the reusable bordered fieldset and window primitives.

Doctors are read-only. Patient histories and appointments can also be managed
from their related Patient and Doctor screens. Prescriptions are managed as
`PatientHistoryMedication` associations from a patient-history record.

Run the controller smoke test with Lua 5.1:

```
lua tests/controller_spec.lua
```
