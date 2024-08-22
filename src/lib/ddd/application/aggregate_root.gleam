import gleam/list
import lib/ddd/model/command.{type Command}
import lib/event_source/application/event_source.{
  type State, type StateReducerFn, State, reduce_events,
}
import lib/event_source/model/event.{type DomainEvent}

pub type DomainError {
  DomainError(message: String)
}

pub type CommandExecutorFunction(c, s, e) =
  fn(Command(c), s) -> Result(List(event.DomainEvent(e)), DomainError)

pub type CommandResult(s, e) {
  CommandResult(state: State(s), events: List(DomainEvent(e)))
}

pub type Aggregate(s, e, c) {
  Aggregate(
    name: String,
    command_handler: CommandExecutorFunction(c, s, e),
    state_resolver: fn(String, String) -> Result(State(s), DomainError),
    state_persiter: fn(String, String, State(s)) ->
      Result(State(s), DomainError),
    events_persister: fn(String, String, List(DomainEvent(e))) ->
      Result(List(DomainEvent(e)), DomainError),
    state_reducer: StateReducerFn(s, e),
  )
}

fn execute_command(
  aggr: Aggregate(s, e, c),
  state: State(s),
  cmd: Command(c),
) -> Result(CommandResult(s, e), DomainError) {
  let command_handler = aggr.command_handler
  let state_reducer = aggr.state_reducer

  case command_handler(cmd, state.data) {
    Ok(cmd_events) -> {
      case reduce_events(state_reducer, cmd_events, state.data) {
        Ok(new_state) -> {
          Ok(CommandResult(
            state: State(
              data: new_state,
              revision: state.revision + list.length(cmd_events),
              id: cmd.aggregate_id,
            ),
            events: cmd_events,
          ))
        }
        Error(error) -> Error(DomainError(message: error.message))
      }
    }
    Error(error) -> Error(error)
  }
}

pub fn mutate_aggregate(
  aggr: Aggregate(s, e, c),
  cmd: Command(c),
) -> Result(CommandResult(s, e), DomainError) {
  let state_result = aggr.state_resolver(aggr.name, cmd.aggregate_id)
  case state_result {
    Ok(state) -> {
      let command_result = execute_command(aggr, state, cmd)
      case command_result {
        Ok(command) -> {
          let events = command.events
          let new_state = command.state
          case
            persist_all(
              aggr.name,
              cmd.aggregate_id,
              events,
              aggr.events_persister,
              aggr.state_persiter,
              new_state,
            )
          {
            Ok(_) -> Ok(CommandResult(state: new_state, events: events))
            Error(error) -> Error(error)
          }
        }
        Error(error) -> Error(error)
      }
    }
    Error(error) -> Error(error)
  }
}

fn persist_all(
  aggregate_name: String,
  aggregate_id: String,
  events: List(DomainEvent(e)),
  events_persister: fn(String, String, List(DomainEvent(e))) ->
    Result(List(DomainEvent(e)), DomainError),
  state_persiter: fn(String, String, State(s)) -> Result(State(s), DomainError),
  new_state: State(s),
) -> Result(State(s), DomainError) {
  events_persister(aggregate_name, aggregate_id, events)
  state_persiter(aggregate_name, aggregate_id, new_state)
}
