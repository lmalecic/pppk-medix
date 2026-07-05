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
