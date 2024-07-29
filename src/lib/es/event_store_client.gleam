import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json, array, int, null, object, string}
import gleam/list
import gleam/option.{type Option, Some}
import gleam/pgo.{type Connection}
import lib/database/simple_orm.{type DatabaseError, Register, find, persist}

pub type ESEvent {
  ESEvent(id: String, name: String, data: Json, metadata: Json, revision: Int)
}

pub type ESPersistenceError {
  ESPersistenceError(message: String)
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

  let result =
    persist(
      stream,
      list.map(events, fn(event) {
        Register(data: [
          #("name", pgo.text(event.name)),
          #("data", pgo.text(json.to_string(event.data))),
          #("metadata", pgo.text(json.to_string(event.metadata))),
          #("revision", pgo.int(event.revision)),
        ])
      }),
      db,
    )
  case result {
    Ok(data) -> Ok(events)
    Error(error) -> Error(ESPersistenceError(error.message))
  }
}

pub fn get_events(
  stream: String,
  revision: Option(Int),
) -> Result(List(ESEvent), ESPersistenceError) {
  let db = connect()
  find(
    stream,
    ["name", "data", "metadata", "revision"],
    [#("revision", pgo.int(0)), #("revision1", pgo.int(0))],
    dynamic.dynamic,
    fn(row: Dynamic) { todo },
  )
  Ok([])
}
