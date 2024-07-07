import gleam/int
import gleam/io
import gleam/json.{type Json, array, int, null, object, string}
import gleam/option.{type Option, None, Some}

pub type Metadata {
  Metadata(
    occurred_at: Option(String),
    correlation_id: Option(String),
    causation_id: Option(String),
    revision: Int,
  )
}

pub type Event(d) {
  Event(data: d, name: String, metadata: Option(Metadata))
}

pub type EventDataToJsonFn(d) =
  fn(d) -> Json

pub fn unwrap_metadata(metadata: Option(Metadata)) -> Metadata {
  option.unwrap(
    metadata,
    Metadata(
      occurred_at: Some(""),
      correlation_id: Some(""),
      causation_id: Some(""),
      revision: 0,
    ),
  )
}

fn metdata_to_json(e: Event(d)) -> Json {
  let metadata = unwrap_metadata(e.metadata)
  object([
    #("revision", int(metadata.revision)),
    #("occurred_at", string("")),
    #("correlation_id", string("")),
    #("causation_id", string("")),
  ])
}

pub fn to_json(e: Event(d), data_to_json_fn: EventDataToJsonFn(d)) -> Json {
  object([
    #("data", data_to_json_fn(e.data)),
    #("metadata", metdata_to_json(e)),
    #("name", string(e.name)),
  ])
}

pub fn to_string(e: Event(d), data_to_json_fn: EventDataToJsonFn(d)) -> String {
  let metadata = unwrap_metadata(e.metadata)
  //to_json(e, data_to_json_fn) |> json.to_string
  "name:" <> e.name <> ",revision:" <> int.to_string(metadata.revision)
}
