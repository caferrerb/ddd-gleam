import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json.{type Json, array, int, null, object, string}
import gleam/option.{type Option, None, Some, unwrap}
import tempo/datetime

pub type Metadata {
  Metadata(
    occurred_at: String,
    correlation_id: String,
    causation_id: String,
    revision: Int,
  )
}

pub type DomainEvent(d) {
  DomainEvent(
    data: d,
    name: String,
    aggregate_id: String,
    metadata: Option(Metadata),
  )
}

pub type EventDataSerializer(d) =
  fn(d) -> Json

pub fn new(
  data: d,
  name: String,
  aggregate_id: String,
  //revision: Option(Int),
  //metadata: Option(Metadata),
) -> DomainEvent(d) {
  //let metadata =
  //option.unwrap(
  // metadata,
  //  build_default_metadata(option.unwrap(revision, 0), None, None),
  //)
  DomainEvent(
    data: data,
    name: name,
    aggregate_id: aggregate_id,
    metadata: None,
  )
}

pub fn build_default_metadata(
  revision: Int,
  correlation_id: Option(String),
  causation_id: Option(String),
) -> Metadata {
  let occurred_at = datetime.now_utc() |> datetime.to_string

  Metadata(
    correlation_id: option.unwrap(correlation_id, ""),
    causation_id: option.unwrap(causation_id, ""),
    revision: revision,
    occurred_at: occurred_at,
  )
}

pub fn unwrap_metadata(metadata: Option(Metadata)) -> Metadata {
  option.unwrap(metadata, build_default_metadata(0, None, None))
}

pub fn metadata_to_json(metadata: Option(Metadata)) -> Json {
  let metadata = unwrap_metadata(metadata)
  object([
    #("revision", int(metadata.revision)),
    #("occurred_at", string(metadata.occurred_at)),
    #("causation_id", string(metadata.causation_id)),
    #("correlation_id", string(metadata.correlation_id)),
  ])
}

pub fn metadata_json_decoder() -> dynamic.Decoder(Metadata) {
  dynamic.decode4(
    Metadata,
    dynamic.field("occurred_at", of: dynamic.string),
    dynamic.field("correlation_id", of: dynamic.string),
    dynamic.field("causation_id", of: dynamic.string),
    dynamic.field("revision", of: dynamic.int),
  )
}

pub fn to_json(
  e: DomainEvent(d),
  data_to_json_fn: EventDataSerializer(d),
) -> Json {
  object([
    #("data", data_to_json_fn(e.data)),
    #("metadata", metadata_to_json(e.metadata)),
    #("name", string(e.name)),
    #("aggregateId", string(e.aggregate_id)),
  ])
}

pub fn to_string(
  e: DomainEvent(d),
  data_to_json_fn: EventDataSerializer(d),
) -> String {
  to_json(e, data_to_json_fn) |> json.to_string
}
