SQLITE_FILE := "anchor.db"

run:
  gleam run

parrot:
  sqlite3 {{SQLITE_FILE}} < ./priv/schema.sql
  gleam run -m parrot -- --sqlite {{SQLITE_FILE}}

