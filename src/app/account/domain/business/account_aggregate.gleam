import app/account/domain/account_commands.{
  type AccountCommandData, create_account_command_handler,
}
import app/account/domain/account_events.{
  type AccountEvent, account_event_to_string, create_account_event_reducer,
}
import app/account/domain/model/account.{type Account}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{unwrap}
import lib/ddd/business/aggregate.{
  type Aggregate, mutate_aggregate, new_aggregate,
}
import lib/ddd/model/command.{type Command}
import lib/ddd/model/error

pub fn build_account_agregate(
  init_account: Account,
) -> Aggregate(Account, AccountEvent, AccountCommandData) {
  new_aggregate(
    init_account,
    create_account_command_handler(),
    create_account_event_reducer(),
  )
}

pub fn account_execute_command(
  aggr: Aggregate(Account, AccountEvent, AccountCommandData),
  cmd: Command(AccountCommandData),
) -> Result(
  Aggregate(Account, AccountEvent, AccountCommandData),
  error.DomainError,
) {
  mutate_aggregate(aggr, cmd)
}

pub fn print_account(aggr: Aggregate(Account, AccountEvent, AccountCommandData)) {
  let account: Account = aggr.state.data
  io.println("available = " <> float.to_string(account.available))
  io.println("credits = " <> float.to_string(account.credits))
  io.println("debits = " <> float.to_string(account.debits))
  io.println("revision = " <> int.to_string(aggr.state.revision))

  io.println("----------events---------")

  list.fold(aggr.events, "", fn(_, event) {
    io.print(account_event_to_string(event) <> "<::>")
    ""
  })
  io.println("")
}
