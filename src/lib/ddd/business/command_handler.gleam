import gleam/dict.{type Dict}
import gleam/result
import lib/ddd/model/command.{type Command}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event}
import lib/ddd/model/state.{type State}

pub type CommandExecutorFunction(c, s, e) =
  fn(Command(c), s) -> Result(List(Event(e)), error.DomainError)

pub type CommandExecuter(c, s, e) {
  CommandExecuter(handlers: Dict(String, CommandExecutorFunction(c, s, e)))
}

pub fn run_command(
  command_executer: CommandExecuter(c, s, e),
  cmd: Command(c),
  s: State(s),
) -> Result(List(Event(e)), error.DomainError) {
  case dict.get(command_executer.handlers, cmd.name) {
    Ok(handler) -> handler(cmd, s.data)
    Error(_) -> Error(error.DomainError("handler not found"))
  }
}
