import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/io
import gleam/json.{type Json, array, int, null, object, string}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection}
import gleam/result
import lib/orm/simple_orm.{
  type DatabaseError, Register, execute_query, find, persist,
}

pub type ESEvent(d, m) {
  ESEvent(
    aggregate_id: String,
    name: String,
    data: d,
    metadata: Option(m),
    revision: Int,
  )
}

pub type ESEventDataSerializer(d) =
  fn(d) -> Json

pub type ESPersistenceError {
  ESPersistenceError(message: String)
}

fn serialize_metadata(metadata: Option(m), metadata_serializer) -> String {
  case metadata {
    Some(metadata) -> {
      case metadata_serializer {
        Some(serializer) -> serializer(metadata) |> json.to_string
        None -> ""
      }
    }
    None -> ""
  }
}

pub fn persist_events(
  aggregate_name: String,
  aggregate_id: String,
  events: List(ESEvent(d, m)),
  data_serializer: ESEventDataSerializer(d),
  metadata_serializer: Option(ESEventDataSerializer(m)),
  connection: Connection,
) -> Result(List(ESEvent(d, m)), ESPersistenceError) {
  let max_revision = get_last_revision(aggregate_name, aggregate_id, connection)
  let result =
    persist(
      aggregate_name,
      list.index_map(events, fn(event, idx) {
        let str_metadata =
          serialize_metadata(event.metadata, metadata_serializer)
        let str_data = data_serializer(event.data) |> json.to_string

        Register(data: [
          #("name", pgo.text(event.name)),
          #("revision", pgo.int(max_revision + idx + 1)),
          #("data", pgo.text(data_serializer(event.data) |> json.to_string)),
          #("metadata", pgo.text(str_metadata)),
          #("aggregate_id", pgo.text(aggregate_id)),
        ])
      }),
      connection,
    )
  case result {
    Ok(data) -> Ok(events)
    Error(error) -> Error(ESPersistenceError(error.message))
  }
}

fn decode_data(str_data: String, decoder: dynamic.Decoder(d)) -> d {
  let decode_result = json.decode(from: str_data, using: decoder)
  case decode_result {
    Ok(data) -> data
    Error(error) -> {
      io.print_error("Error decoding data:" <> str_data)
      case error {
        json.UnexpectedEndOfInput -> io.println_error(" UnexpectedEndOfInput")
        json.UnexpectedByte(_, ..) -> io.println_error(" UnexpectedByte")
        json.UnexpectedSequence(_, ..) ->
          io.println_error(" UnexpectedSequence")
        json.UnexpectedFormat(errors) -> {
          list.each(errors, fn(error) {
            io.println_error(
              " UnexpectedFormat: expected="
              <> error.expected
              <> ",found="
              <> error.found
              <> ",path=",
              //<> error.path,
            )
          })
        }
      }
      panic
    }
  }
}

fn get_last_revision(
  aggregate_name: String,
  aggregate_id: String,
  connection: Connection,
) -> Int {
  let query =
    "SELECT max(revision),1 FROM "
    <> aggregate_name
    <> " WHERE aggregate_id =$1"
  let result =
    execute_query(
      query,
      [pgo.text(aggregate_id)],
      dynamic.tuple2(dynamic.int, dynamic.int),
      fn(rows) {
        list.map(rows, fn(row) {
          let #(max, _) = row
          max
        })
      },
      connection,
    )
  case result {
    Ok(rows) -> {
      let max = case rows {
        [max, ..] -> max
        [] -> 0
      }
      max
    }
    Error(error) -> 0
  }
}

pub fn get_events(
  aggregate_name: String,
  aggregate_id: String,
  revision: Option(Int),
  data_deserializer: fn(String) -> dynamic.Decoder(d),
  metadata_deserializer: Option(dynamic.Decoder(m)),
  connection: Connection,
) -> Result(List(ESEvent(d, m)), ESPersistenceError) {
  let row_type =
    dynamic.tuple4(dynamic.string, dynamic.string, dynamic.string, dynamic.int)

  let revision_value = case revision {
    Some(value) -> value
    None -> 0
  }
  let query =
    "SELECT name,data,metadata,revision FROM "
    <> aggregate_name
    <> " WHERE aggregate_id =$1 AND revision >=$2 ORDER BY revision asc"

  let result =
    execute_query(
      query,
      [pgo.text(aggregate_id), pgo.int(revision_value)],
      row_type,
      fn(rows) {
        io.println("mapping:" <> int.to_string(list.length(rows)))
        list.map(rows, fn(row) {
          let #(name, str_data, str_metadata, revision) = row
          let metadata = case metadata_deserializer {
            Some(deserializer) -> {
              case str_metadata {
                "" -> None
                _ -> Some(decode_data(str_metadata, deserializer))
              }
            }
            None -> None
          }
          ESEvent(
            name: name,
            aggregate_id: aggregate_id,
            data: decode_data(str_data, data_deserializer(name)),
            metadata: metadata,
            revision: revision,
          )
        })
      },
      connection,
    )

  case result {
    Ok(events) -> Ok(events)
    Error(error) -> Error(ESPersistenceError(error.message))
  }
}

pub fn event_to_string(
  event: ESEvent(d, m),
  data_serializer: ESEventDataSerializer(d),
  metadata_serializer: Option(ESEventDataSerializer(m)),
) -> String {
  object([
    #("name", string(event.name)),
    #("aggregate_id", string(event.aggregate_id)),
    #("revision", string(int.to_string(event.revision))),
    #("data", string(data_serializer(event.data) |> json.to_string)),
    #(
      "metadata",
      string(serialize_metadata(event.metadata, metadata_serializer)),
    ),
  ])
  |> json.to_string
}
