import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import lib/ddd/business/command_handler.{type CommandExecuter, run_command}
import lib/ddd/business/state_reducer.{type StateReducer, reduce_events}
import lib/ddd/model/command.{type Command}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event, Event, Metadata}
import lib/ddd/model/state

pub type Aggregate(s, e, c) {
  Aggregate(
    state: state.State(s),
    events: List(Event(e)),
    command_handler: CommandExecuter(c, s, e),
    reducer: StateReducer(s, e),
  )
}

pub fn new_aggregate(
  init_state: s,
  command_handler: CommandExecuter(c, s, e),
  reducer: StateReducer(s, e),
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

  case run_command(command_handler, cmd, aggre_state) {
    Ok(cmd_events) -> {
      case reduce_events(reducer, cmd_events, aggre_state.data) {
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
