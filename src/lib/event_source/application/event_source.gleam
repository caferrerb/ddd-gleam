import gleam/io
import gleam/json.{type Json, array, float, int, object, string}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection}
import gleam/result

import lib/event_source/infraestructure/db_event_store_client.{
  type ESEvent, ESEvent,
}
import lib/event_source/model/event.{
  type DomainEvent, DomainEvent, metadata_json_decoder, metadata_to_json,
  unwrap_metadata,
}

import gleam/dynamic.{type Dynamic}

pub type EventSourceError {
  EventSourceError(message: String)
}

pub type State(data) {
  State(id: String, data: data, revision: Int)
}

pub type StateReducerFn(s, e) =
  fn(e, s) -> Result(s, EventSourceError)

pub fn persist_events(
  aggregate: String,
  id: String,
  events: List(DomainEvent(d)),
  data_serializer_fn: fn(d) -> Json,
  connection: Connection,
) -> Result(List(DomainEvent(d)), EventSourceError) {
  let event_to_persist =
    list.map(events, fn(event) {
      let metadata = unwrap_metadata(event.metadata)
      ESEvent(
        aggregate_id: id,
        name: event.name,
        data: event.data,
        metadata: Some(event.metadata),
        revision: metadata.revision,
      )
    })
  case
    db_event_store_client.persist_events(
      aggregate,
      id,
      event_to_persist,
      data_serializer_fn,
      Some(metadata_to_json),
      connection,
    )
  {
    Ok(_) -> Ok(events)
    Error(error) -> Error(EventSourceError(error.message))
  }
}

pub fn get_events(
  aggregate: String,
  id: String,
  from_revision: Option(Int),
  data_decoder: fn(String) -> dynamic.Decoder(d),
  connection: Connection,
) -> Result(List(DomainEvent(d)), EventSourceError) {
  case
    db_event_store_client.get_events(
      aggregate,
      id,
      from_revision,
      data_decoder,
      Some(metadata_json_decoder()),
      connection,
    )
  {
    Ok(events) -> {
      Ok(
        list.map(events, fn(event) {
          let metadata = case event.metadata {
            Some(m) -> Some(event.Metadata(..m, revision: event.revision))
            None -> None
          }
          DomainEvent(
            data: event.data,
            name: event.name,
            aggregate_id: event.aggregate_id,
            metadata: metadata,
          )
        }),
      )
    }
    Error(error) -> Error(EventSourceError(error.message))
  }
}

pub fn reduce_events(
  state_reducer: StateReducerFn(s, e),
  events: List(DomainEvent(e)),
  initial_state: s,
) -> Result(s, EventSourceError) {
  list.fold(events, Ok(initial_state), fn(acc_state, event) {
    use new_state <- result.try(acc_state)
    case state_reducer(event.data, new_state) {
      Ok(reduction) -> Ok(reduction)
      Error(_) ->
        Error(EventSourceError(message: "Error applying event " <> event.name))
    }
  })
}

fn get_last_revision(events: List(DomainEvent(d))) -> Int {
  let last_event_result = list.last(events)

  case last_event_result {
    Ok(last) -> {
      case last.metadata {
        Some(metadata) -> metadata.revision
        None -> 0
      }
    }
    Error(_) -> 0
  }
}

pub fn get_state_from_events(
  aggregate: String,
  id: String,
  state_reducer: StateReducerFn(s, d),
  initial_state: State(s),
  data_decoder: fn(String) -> dynamic.Decoder(d),
  connection: Connection,
) -> Result(State(s), EventSourceError) {
  case get_events(aggregate, id, Some(0), data_decoder, connection) {
    Ok(events) -> {
      //list.each(events, fn(e) {
      //  io.println(event.metadata_to_json(e.metadata) |> json.to_string)
      //})

      let state_result =
        reduce_events(state_reducer, events, initial_state.data)
      use state_data <- result.try(state_result)

      let last_revision = get_last_revision(events)
      let new_state =
        State(revision: last_revision, data: state_data, id: initial_state.id)
      Ok(new_state)
    }
    Error(error) -> Error(EventSourceError(error.message))
  }
}
