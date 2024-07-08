import app/account/domain/account_events.{
  type AccountEvent, build_account_created_event, build_account_credited_event,
  build_account_debited_event,
}
import app/account/domain/model/account
import gleam/dict
import gleam/io
import gleam/option.{type Option}
import lib/ddd/model/command.{type Command}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event}
import lib/ddd/model/state.{type State}

pub const create_account_command: String = "create_account"

pub const credit_account_command: String = "credit_account"

pub const debit_account_command: String = "debit_account"

pub type AccountCommandData {
  CreateAccountCommandData(id: String, created_at: Option(String))
  CreditAccountCommandData(amount: Float, credited_at: Option(String))
  DebitedAccountCommandData(amount: Float, debited_at: Option(String))
}

pub fn execute_account_command(
  cmd: Command(AccountCommandData),
  account: account.Account,
) -> Result(List(Event(AccountEvent)), error.DomainError) {
  io.debug("++++create_account cmd+++")
  case cmd.data {
    CreateAccountCommandData(id, created_at) ->
      Ok([build_account_created_event(id, created_at)])
    CreditAccountCommandData(amount, credited_at) ->
      Ok([build_account_credited_event(amount, credited_at)])
    DebitedAccountCommandData(amount, debited_at) -> {
      case account.available >=. amount {
        True -> Ok([build_account_debited_event(amount, debited_at)])
        False -> Error(error.DomainError("no funds"))
      }
    }
    _ -> Error(error.DomainError("no command"))
  }
}
