import gleam/result
import gleam/time/timestamp
import parrot/dev
import sqlight

pub type Error {
  DbError(sqlight.Error)
  ExpectedOnlyOne
}

pub fn open(path: String) -> Result(sqlight.Connection, sqlight.Error) {
  use conn <- result.try(sqlight.open(path))
  use _ <- result.try(sqlight.exec("PRAGMA journal_mode=WAL;", conn))
  use _ <- result.try(sqlight.exec("PRAGMA busy_timeout=5000;", conn))
  use _ <- result.try(sqlight.exec("PRAGMA foreign_keys=ON;", conn))
  Ok(conn)
}

pub fn parrot_to_sqlight(param: dev.Param) -> sqlight.Value {
  case param {
    dev.ParamFloat(x) -> sqlight.float(x)
    dev.ParamInt(x) -> sqlight.int(x)
    dev.ParamString(x) -> sqlight.text(x)
    dev.ParamBitArray(x) -> sqlight.blob(x)
    dev.ParamNullable(x) -> sqlight.nullable(fn(a) { parrot_to_sqlight(a) }, x)
    dev.ParamList(_) -> panic as "sqlite does not implement lists"
    dev.ParamBool(bool) -> sqlight.bool(bool)
    dev.ParamDate(_) -> panic as "sqlite does not support dates"
    dev.ParamTimestamp(ts) -> {
      let #(seconds, nanoseconds) =
        timestamp.to_unix_seconds_and_nanoseconds(ts)
      let microseconds = seconds * 1_000_000 + nanoseconds / 1000
      sqlight.int(microseconds)
    }
    dev.ParamDynamic(_) -> panic as "sqlite does not support dynamic params"
  }
}

pub fn expect_one(rows: Result(List(a), sqlight.Error)) -> Result(a, Error) {
  case rows {
    Ok([row]) -> Ok(row)
    Ok(_) -> Error(ExpectedOnlyOne)
    Error(err) -> Error(DbError(err))
  }
}
