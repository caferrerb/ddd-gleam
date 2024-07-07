import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import lib/ddd/model/error
import lib/ddd/model/event.{type Event}
import lib/ddd/model/state.{type State, State}

pub type StateReducerFn(s, e) =
  fn(Event(e), s) -> Result(s, error.DomainError)

pub type StateReducer(s, e) {
  StateReducer(reducers: Dict(String, StateReducerFn(s, e)))
}

pub fn reduce(
  state_reducer: StateReducer(s, e),
  event: Event(e),
  state: s,
) -> Result(s, error.DomainError) {
  let event_name = event.name
  case dict.get(state_reducer.reducers, event_name) {
    Ok(reducer) -> reducer(event, state)
    Error(_) -> Ok(state)
  }
}

pub fn reduce_events(
  state_reducer: StateReducer(s, e),
  events: List(Event(e)),
  initial_state: s,
) -> Result(s, error.DomainError) {
  list.fold(events, Ok(initial_state), fn(acc_state, event) {
    use new_state <- result.try(acc_state)
    case reduce(state_reducer, event, new_state) {
      Ok(reduction) -> Ok(reduction)
      Error(_) ->
        Error(error.DomainError("Error applying event " <> event.name))
    }
  })
}
