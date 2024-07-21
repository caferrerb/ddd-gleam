import app/account/domain/model/account.{type Account, new}
import gleam/float
import gleam/int
import gleam/io
import gleam/option.{type Option, Some}
import lib/ddd/model/error
import lib/ddd/model/state.{type State}

pub fn persist_account_state(
  aggregate: String,
  state: State(Account),
) -> Result(State(Account), error.DomainError) {
  io.debug("persisting state for " <> aggregate <> "=" <> state.id)
  let account: Account = state.data
  io.println("available = " <> float.to_string(account.available))
  io.println("credits = " <> float.to_string(account.credits))
  io.println("debits = " <> float.to_string(account.debits))
  io.println("revision = " <> int.to_string(state.revision))
  Ok(state)
}

pub fn get_account_state(
  aggregate: String,
  id: String,
) -> Result(Option(State(Account)), error.DomainError) {
  let state = state.State(data: new(id), revision: 0, id: id)
  io.debug("getting state for " <> aggregate <> "=" <> state.id)

  Ok(Some(state))
}
