import app/account/domain/account_commands.{
  type AccountCommandData, execute_account_command,
}
import app/account/domain/account_events.{
  type AccountEvent, account_event_to_string, handle_account_events,
}
import app/account/domain/model/account.{type Account, new}
import lib/ddd/business/aggregate.{
  type Aggregate, type CommandResult, mutate_aggregate, new_aggregate,
}
import lib/ddd/model/command.{type Command}
import lib/ddd/model/error

import app/account/application/account_event_store.{
  get_account_events, persist_account_events,
}
import app/account/application/account_state_store.{
  get_account_state, persist_account_state,
}

pub fn build_account_agregate() -> Aggregate(
  Account,
  AccountEvent,
  AccountCommandData,
) {
  new_aggregate(
    "account",
    fn() { new("") },
    execute_account_command,
    handle_account_events,
    get_account_events,
    persist_account_events,
    get_account_state,
    persist_account_state,
  )
}

pub fn account_execute_command(
  aggr: Aggregate(Account, AccountEvent, AccountCommandData),
  cmd: Command(AccountCommandData),
) -> Result(CommandResult(Account, AccountEvent), error.DomainError) {
  mutate_aggregate(aggr, cmd)
}
