import app/account/domain/model/account.{type Account}
import gleam/dict.{type Dict}
import gleam/io
import gleam/json.{type Json, array, float, int, object, string}
import gleam/option.{type Option}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event}
import lib/ddd/model/state.{type State}

pub const account_created_event_name: String = "AccountCreated"

pub const account_credited_event_name: String = "AccountCredited"

pub const account_debited_event_name: String = "AccountDebited"

pub type AccountEvent {
  AccountCredited(amount: Float, credited_at: String)
  AccountDebited(amount: Float, debited_at: String)
  AccountCreated(id: String, created_at: String)
}

pub fn build_account_created_event(
  id: String,
  created_at: Option(String),
) -> Event(AccountEvent) {
  event.Event(
    data: AccountCreated(id: id, created_at: option.unwrap(created_at, "")),
    metadata: option.None,
    name: account_created_event_name,
  )
}

pub fn build_account_credited_event(
  amount: Float,
  credited_at: Option(String),
) -> Event(AccountEvent) {
  event.Event(
    data: AccountCredited(
      amount: amount,
      credited_at: option.unwrap(credited_at, ""),
    ),
    metadata: option.None,
    name: account_credited_event_name,
  )
}

pub fn build_account_debited_event(
  amount: Float,
  debited_at: Option(String),
) -> Event(AccountEvent) {
  event.Event(
    data: AccountDebited(
      amount: amount,
      debited_at: option.unwrap(debited_at, ""),
    ),
    metadata: option.None,
    name: account_debited_event_name,
  )
}

pub fn handle_account_events(
  event: event.Event(AccountEvent),
  account: account.Account,
) -> Result(account.Account, error.DomainError) {
  io.debug("account_created_handler")
  case event.data {
    AccountCreated(id, ..) ->
      Ok(account.Account(credits: 0.0, debits: 0.0, id: id, available: 0.0))
    AccountCredited(amount, _) -> {
      let account.Account(credits, available, ..) = account
      let new_account =
        account.Account(
          ..account,
          credits: credits +. amount,
          available: available +. amount,
        )
      Ok(new_account)
    }
    AccountDebited(amount, _) -> {
      let account.Account(available, debits, ..) = account
      let new_account =
        account.Account(
          ..account,
          debits: debits +. amount,
          available: available -. amount,
        )
      Ok(new_account)
    }
    _ -> Ok(account)
  }
}

fn account_event_data_to_json(data: AccountEvent) -> Json {
  case data {
    AccountCreated(id, created_at) ->
      object([#("id", string(id)), #("created_at", string(created_at))])

    AccountDebited(amount, debited_at) ->
      object([#("amount", float(amount)), #("debited_at", string(debited_at))])

    AccountCredited(amount, credited_at) ->
      object([#("amount", float(amount)), #("credited_at", string(credited_at))])
    _ -> json.null()
  }
}

pub fn account_event_to_json(e: event.Event(AccountEvent)) -> Json {
  event.to_json(e, account_event_data_to_json)
}

pub fn account_event_to_string(e: event.Event(AccountEvent)) -> String {
  event.to_string(e, account_event_data_to_json)
}
