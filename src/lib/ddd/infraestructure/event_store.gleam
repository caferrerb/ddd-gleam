import gleam/json.{type Json, array, int, null, object, string}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lib/ddd/business/event_reducer.{type StateReducerFn, reduce_events}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event, type EventDataToJsonFn, Event, to_json}
import lib/ddd/model/state

pub type GetEventsFromStateStore(e) =
  fn(String, String) -> Result(Option(List(Event(e))), error.DomainError)

pub type SaveEventsToStateStore(e) =
  fn(String, String, List(Event(e))) ->
    Result(List(Event(e)), error.DomainError)

pub fn build_state_from_events(
  aggregate: String,
  id: String,
  events_getter: GetEventsFromStateStore(e),
  reducer: StateReducerFn(s, e),
  init_state_builder: fn() -> s,
) -> Result(Option(state.State(s)), error.DomainError) {
  let events_result = events_getter(aggregate, id)

  case events_result {
    Ok(optional_events) -> {
      case optional_events {
        Some(events) -> {
          use state <- result.try(reduce_events(
            reducer,
            events,
            init_state_builder(),
          ))
          Ok(
            Some(state.State(id: id, data: state, revision: list.length(events))),
          )
        }
        None -> Ok(None)
      }
    }
    Error(error) -> Error(error.DomainError("Error fetching events"))
  }
}

pub fn persist_events(
  aggregate: String,
  id: String,
  events: List(Event(e)),
  event_saver: SaveEventsToStateStore(e),
) -> Result(List(Event(e)), error.DomainError) {
  event_saver(aggregate, id, events)
}

pub fn get_events(
  aggregate: String,
  id: String,
  event_getter: GetEventsFromStateStore(e),
) -> Result(List(Event(e)), error.DomainError) {
  todo
  //event_getter(aggregate, id)
}
