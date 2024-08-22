import gleam/list
import gleam/result

import lib/event_source/model/event.{
  type DomainEvent, DomainEvent, metadata_json_decoder, metadata_to_json,
  unwrap_metadata,
}

pub type EventStateReducerError {
  EventStateReducerError(message: String)
}

pub type StateReducerFn(s, e) =
  fn(DomainEvent(e), s) -> Result(s, EventStateReducerError)

pub fn reduce_events(
  state_reducer: StateReducerFn(s, e),
  events: List(DomainEvent(e)),
  initial_state: s,
) -> Result(s, EventStateReducerError) {
  list.fold(events, Ok(initial_state), fn(acc_state, event) {
    use new_state <- result.try(acc_state)
    case state_reducer(event, new_state) {
      Ok(reduction) -> Ok(reduction)
      Error(_) ->
        Error(EventStateReducerError(
          message: "Error applying event " <> event.name,
        ))
    }
  })
}
