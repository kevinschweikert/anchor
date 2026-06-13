# override with an absolute path so the server (cwd: server/) and dbmate
# (cwd: repo root) resolve the same file, e.g. DATABASE_PATH=/data/anchor.db
sqlite_file := env("DATABASE_PATH", "server/anchor_dev.db")
dbmate := "dbmate --url sqlite:" + sqlite_file + " --migrations-dir server/priv/migrations --no-dump-schema"

# run the backend server
run:
  cd server && gleam run

# build all frontend projects and move them to the server static folder
build project:
  cd {{project}} && gleam run -m lustre/dev build --minify

# bundle widget.js and app.js into server/priv/static
build-all: (build "widget") (build "app")

# hot-reloading dev server for a client package: just dev widget | just dev app
dev project:
  cd {{project}} && gleam run -m lustre/dev start

# api server (:8000) + widget (:1234) + app (:1235) in one mprocs session
dev-all:
  mprocs --names server,widget,app "just run" "just dev widget" "just dev app"

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

upgrade-daisy:
  curl -sLo app/src/daisyui.js https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.js
  curl -sLo app/src/daisyui-theme.js https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.js
