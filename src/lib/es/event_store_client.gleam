import gleam/dynamic
import gleam/int
import gleam/string
import gleam/string_builder

import gleam/io
import gleam/json.{type Json, array, int, null, object, string}
import gleam/list
import gleam/option.{type Option, Some}
import gleam/pgo.{type Connection}
import gleeunit/should

pub type ESEvent {
  ESEvent(id: String, name: String, data: Json, metadata: Json, revision: Int)
}

pub type ESPersistenceError {
  ESPErsistError(message: String)
}

fn connect() -> Connection {
  pgo.connect(
    pgo.Config(
      ..pgo.default_config(),
      host: "localhost",
      password: Some("mundisecret"),
      user: "mundi",
      database: "db",
      port: 65_432,
      pool_size: 15,
    ),
  )
}

pub fn persist_events(
  stream: String,
  events: List(ESEvent),
) -> Result(List(ESEvent), ESPersistenceError) {
  let db = connect()

  let i = 0
  let str_values = ""
  let sql_values =
    list.fold(events, "", fn(acc, event) {
      let result =
        string.append(
          acc,
          "("
            <> "$"
            <> int.to_string(i + 1)
            <> ","
            <> "$"
            <> int.to_string(i + 2)
            <> ","
            <> "$"
            <> int.to_string(i + 3)
            <> ","
            <> "$"
            <> int.to_string(i + 4)
            <> "),",
        )
      let i = i + 4
      result
    })
  let values =
    list.fold(events, [], fn(acc, event) {
      list.append(acc, [
        pgo.text(event.name),
        pgo.text(json.to_string(event.data)),
        pgo.text(json.to_string(event.metadata)),
        pgo.int(event.revision),
      ])
    })
  //io.println(list.to_string(values))
  let query =
    "insert into "
    <> stream
    <> "(name, data, metadata,revision) values "
    <> string.slice(sql_values, 0, string.length(sql_values) - 1)

  io.println(query)

  let result = pgo.execute(query, db, values, dynamic.dynamic)
  case result {
    Ok(_) -> Ok(events)
    Error(e) -> {
      case e {
        pgo.PostgresqlError(code, name, message) -> {
          io.println_error(code <> name <> message)
        }
        pgo.ConnectionUnavailable -> {
          io.println_error("ConnectionUnavailable")
        }
        pgo.ConstraintViolated(e, g, f) -> {
          io.println_error("ConstraintViolated" <> e <> g <> f)
        }
        pgo.UnexpectedArgumentCount(e, g) -> {
          io.println_error(
            "UnexpectedArgumentCount"
            <> int.to_string(e)
            <> "_"
            <> int.to_string(g),
          )
        }
        pgo.UnexpectedArgumentType(e, g) -> {
          io.println_error("UnexpectedArgumentType---" <> e <> "_" <> g)
        }
        pgo.UnexpectedResultType(_) -> {
          io.println_error("UnexpectedResultType")
        }
      }

      Error(ESPErsistError(""))
    }
  }
}

pub fn get_events(
  stream: String,
  revision: Option(Int),
) -> Result(List(ESEvent), ESPersistenceError) {
  let db = connect()

  Ok([])
}
