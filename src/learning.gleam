import app/account/domain/account_commands.{
  type AccountCommandData, CreateAccountCommandData, CreditAccountCommandData,
  DebitedAccountCommandData,
}
import app/account/domain/account_events.{type AccountEvent}
import app/account/domain/business/account_aggregate.{
  account_execute_command, build_account_agregate,
}
import app/account/domain/model/account.{type Account}
import gleam/io
import gleam/option.{None, Some}
import gleam/result
import lib/ddd/business/aggregate.{type Aggregate, type CommandResult}
import lib/ddd/model/command.{Command}

pub fn main() {
  let init_account = account.new("")
  let aggr = build_account_agregate()

  use result: CommandResult(Account, AccountEvent) <- result.try(
    account_execute_command(
      aggr,
      Command(
        aggregate_id: "1",
        data: CreateAccountCommandData(id: "1", created_at: Some("2024-1-1")),
        metadata: None,
        name: "create_account",
      ),
    ),
  )

  use result: CommandResult(Account, AccountEvent) <- result.try(
    account_execute_command(
      aggr,
      Command(
        aggregate_id: "1",
        data: CreditAccountCommandData(
          amount: 100.0,
          credited_at: Some("2024-1-1"),
        ),
        metadata: None,
        name: "credit_account",
      ),
    ),
  )

  use result: CommandResult(Account, AccountEvent) <- result.try(
    account_execute_command(
      aggr,
      Command(
        aggregate_id: "1",
        data: DebitedAccountCommandData(
          amount: 10.0,
          debited_at: Some("2024-1-1"),
        ),
        metadata: None,
        name: "debit_account",
      ),
    ),
  )

  Ok(Nil)
}
