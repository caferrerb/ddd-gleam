import gleam/io
import gleam/list
import gleam/option.{None, Some, unwrap}
import lib/ddd/business/event_reducer.{type StateReducerFn, reduce_events}
import lib/ddd/infraestructure/event_store.{
  type GetEventsFromStateStore, type SaveEventsToStateStore, persist_events,
}
import lib/ddd/model/command.{type Command}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event, Event, Metadata}
import lib/ddd/model/state

import lib/ddd/infraestructure/state_store.{
  type StateStoreGetFn, type StateStorePersistFn,
}

pub type CommandExecutorFunction(c, s, e) =
  fn(Command(c), s) -> Result(List(Event(e)), error.DomainError)

pub type CommandResult(s, e) {
  CommandResult(state: state.State(s), events: List(Event(e)))
}

pub type Aggregate(s, e, c) {
  Aggregate(
    name: String,
    command_handler: CommandExecutorFunction(c, s, e),
    init_state_builder: fn() -> s,
    reducer: StateReducerFn(s, e),
    events_getter: GetEventsFromStateStore(e),
    events_persiter: SaveEventsToStateStore(e),
    state_getter: StateStoreGetFn(s),
    state_persister: StateStorePersistFn(s),
  )
}

pub fn new_aggregate(
  name: String,
  init_state_builder: fn() -> s,
  command_handler: CommandExecutorFunction(c, s, e),
  reducer: StateReducerFn(s, e),
  events_recovery_fn: GetEventsFromStateStore(e),
  events_persist_fn: SaveEventsToStateStore(e),
  state_getter: StateStoreGetFn(s),
  state_persister: StateStorePersistFn(s),
) -> Aggregate(s, e, c) {
  Aggregate(
    name: name,
    command_handler: command_handler,
    init_state_builder: init_state_builder,
    reducer: reducer,
    events_getter: events_recovery_fn,
    events_persiter: events_persist_fn,
    state_getter: state_getter,
    state_persister: state_persister,
  )
}

pub fn mutate_aggregate(
  aggr: Aggregate(s, e, c),
  cmd: Command(c),
) -> Result(CommandResult(s, e), error.DomainError) {
  aggr.events_getter(aggr.name, cmd.aggregate_id)
  case aggr.state_getter(aggr.name, cmd.aggregate_id) {
    Ok(option_state) -> {
      let default_state =
        state.State(
          id: cmd.aggregate_id,
          data: aggr.init_state_builder(),
          revision: 0,
        )
      execute_command(aggr, unwrap(option_state, default_state), cmd)
    }
    Error(error) ->
      Error(error.DomainError(
        "error getting state aggregate " <> cmd.aggregate_id,
      ))
  }
}

fn execute_command(
  aggr: Aggregate(s, e, c),
  aggre_state: state.State(s),
  cmd: Command(c),
) -> Result(CommandResult(s, e), error.DomainError) {
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

          let new_revision = init_revision + list.length(cmd_events)
          let new_state =
            state.State(
              id: cmd.aggregate_id,
              data: data_state,
              revision: new_revision,
            )
          case
            persist_events(
              aggr.name,
              new_state.id,
              events,
              aggr.events_persiter,
            )
          {
            Ok(_) ->
              case aggr.state_persister(aggr.name, new_state) {
                Ok(_) -> Ok(CommandResult(events: events, state: new_state))
                Error(error) -> Error(error)
              }
            Error(error) -> Error(error)
          }
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
