# override with an absolute path so the server (cwd: server/) and dbmate
# (cwd: repo root) resolve the same file, e.g. DATABASE_PATH=/data/anchor.db
sqlite_file := env("DATABASE_PATH", "server/anchor_dev.db")
dbmate := "dbmate --url sqlite:" + sqlite_file + " --migrations-dir server/priv/migrations --no-dump-schema"

# run the backend server
run:
  cd server && gleam run

# bundle widget.js and admin.js into server/priv/static
build: build-widget build-admin

build-widget:
  cd widget && gleam run -m lustre/dev build --minify

build-admin:
  cd admin && gleam run -m lustre/dev build --minify

# hot-reloading dev server for a client package: just dev widget | just dev admin
dev project:
  cd {{project}} && gleam run -m lustre/dev start

# api server (:8000) + widget (:1234) + admin (:1235) in one mprocs session
dev-all:
  mprocs --names server,widget,admin "just run" "just dev widget" "just dev admin"

# create a new migration: just migration add_bookings
migration name:
  {{dbmate}} new {{name}}

migrate-up:
  {{dbmate}} up

# roll back the most recent migration
migrate-down:
  {{dbmate}} rollback

migrate-status:
  {{dbmate}} status

# apply migrations, then regenerate the parrot sql bindings from the live schema
parrot: migrate-up
  cd server && gleam run -m parrot -- --sqlite anchor_dev.db

seed:
  sqlite3 {{sqlite_file}} < server/priv/seed.sql
