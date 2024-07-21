import gleam/list
import gleam/result
import lib/ddd/model/error
import lib/ddd/model/event.{type Event, Event, Metadata}

pub type StateReducerFn(s, e) =
  fn(Event(e), s) -> Result(s, error.DomainError)

pub fn reduce_events(
  state_reducer: StateReducerFn(s, e),
  events: List(Event(e)),
  initial_state: s,
) -> Result(s, error.DomainError) {
  list.fold(events, Ok(initial_state), fn(acc_state, event) {
    use new_state <- result.try(acc_state)
    case state_reducer(event, new_state) {
      Ok(reduction) -> Ok(reduction)
      Error(_) ->
        Error(error.DomainError("Error applying event " <> event.name))
    }
  })
}
