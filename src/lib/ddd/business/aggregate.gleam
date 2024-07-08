import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import lib/ddd/model/command.{type Command}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event, Event, Metadata}
import lib/ddd/model/state.{type State}

pub type CommandExecutorFunction(c, s, e) =
  fn(Command(c), s) -> Result(List(Event(e)), error.DomainError)

pub type StateReducerFn(s, e) =
  fn(Event(e), s) -> Result(s, error.DomainError)

pub type Aggregate(s, e, c) {
  Aggregate(
    state: state.State(s),
    events: List(Event(e)),
    command_handler: CommandExecutorFunction(c, s, e),
    reducer: StateReducerFn(s, e),
  )
}

fn reduce_events(
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

pub fn new_aggregate(
  init_state: s,
  command_handler: CommandExecutorFunction(c, s, e),
  reducer: StateReducerFn(s, e),
) -> Aggregate(s, e, c) {
  let state: state.State(s) = state.State(data: init_state, revision: 0)
  Aggregate(
    state: state,
    events: [],
    command_handler: command_handler,
    reducer: reducer,
  )
}

pub fn mutate_aggregate(
  aggr: Aggregate(s, e, c),
  cmd: Command(c),
) -> Result(Aggregate(s, e, c), error.DomainError) {
  let command_handler = aggr.command_handler
  let reducer = aggr.reducer
  let aggre_state = aggr.state
  let init_revision = aggre_state.revision

  case aggr.command_handler(cmd, aggre_state.data) {
    Ok(cmd_events) -> {
      case reduce_events(aggr.reducer, cmd_events, aggre_state.data) {
        Ok(data_state) -> {
          let events =
            list.map(cmd_events, fn(event) {
              let init_revision = init_revision + 1
              Event(
                ..event,
                metadata: Some(Metadata(
                  occurred_at: None,
                  correlation_id: None,
                  causation_id: None,
                  revision: init_revision,
                )),
              )
            })
            |> list.append(aggr.events, _)

          let new_revision = init_revision + list.length(cmd_events)
          let new_state = state.State(data: data_state, revision: new_revision)
          Ok(Aggregate(..aggr, state: new_state, events: events))
        }
        Error(e) -> {
          Error(e)
        }
      }
    }
    Error(e) -> {
      io.debug(
        "error executing command " <> cmd.name <> " with error:: " <> e.message,
      )
      Error(e)
    }
  }
}
