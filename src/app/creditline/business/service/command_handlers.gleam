import app/creditline/business/model/commands.{type CreditLineCommand}
import app/creditline/business/model/creditline.{type CreditLine, Blocked, Open}
import app/creditline/business/model/events.{
  type CreditLineEvent, build_activated_event, build_blocked_event,
  build_close_event, build_created_event, build_deposited_event,
  build_withdrawn_event,
}
import lib/ddd/application/aggregate_root.{type DomainError, DomainError}
import lib/ddd/model/command.{type Command}
import lib/event_source/model/event

fn handle_create_creditline(
  id: String,
  max_amount: Float,
  business_product_id: String,
) -> Result(List(event.DomainEvent(CreditLineEvent)), DomainError) {
  let events = [build_created_event(id, max_amount, business_product_id)]
  Ok(events)
}

fn handle_deposit_creditline(
  amount: Float,
  credit_line: CreditLine,
) -> Result(List(event.DomainEvent(CreditLineEvent)), DomainError) {
  case credit_line.state {
    Open -> {
      case amount +. credit_line.balance <=. credit_line.max_amount {
        True -> {
          let events = [build_deposited_event(credit_line.id, amount)]
          Ok(events)
        }
        False ->
          Error(DomainError(message: "unable to deposit beyond max_amount"))
      }
    }
    _ -> Error(DomainError(message: "CreditLine in invalid state"))
  }
}

fn handle_withdraw_creditline(
  amount: Float,
  credit_line: CreditLine,
) -> Result(List(event.DomainEvent(CreditLineEvent)), DomainError) {
  case credit_line.state {
    Open -> {
      case amount <. credit_line.available {
        True -> {
          let events = [build_withdrawn_event(credit_line.id, amount)]
          Ok(events)
        }
        False -> Error(DomainError(message: "insufficient available funds"))
      }
    }
    _ -> Error(DomainError(message: "CreditLine in invalid state"))
  }
}

fn handle_block_creditline(
  creditline: CreditLine,
) -> Result(List(event.DomainEvent(CreditLineEvent)), DomainError) {
  case creditline.state {
    Open -> {
      let events = [build_blocked_event(creditline.id)]
      Ok(events)
    }
    _ -> Error(DomainError(message: "CreditLine in invalid state"))
  }
}

fn handle_active_creditline(
  creditline: CreditLine,
) -> Result(List(event.DomainEvent(CreditLineEvent)), DomainError) {
  case creditline.state {
    Blocked -> {
      let events = [build_activated_event(creditline.id)]
      Ok(events)
    }
    _ -> Error(DomainError(message: "CreditLine in invalid state"))
  }
}

fn handle_close_creditline(
  creditline: CreditLine,
) -> Result(List(event.DomainEvent(CreditLineEvent)), DomainError) {
  case creditline.state {
    Open -> {
      case creditline.used_amount >. 0.0 {
        False -> {
          let events = [build_close_event(creditline.id)]
          Ok(events)
        }
        True -> Error(DomainError(message: "used creditline yet"))
      }
    }
    _ -> Error(DomainError(message: "CreditLine in invalid state"))
  }
}

pub fn command_handler(
  cmd: Command(CreditLineCommand),
  state: CreditLine,
) -> Result(List(event.DomainEvent(CreditLineEvent)), DomainError) {
  case cmd.data {
    commands.Deposit(amount, _) -> handle_deposit_creditline(amount, state)
    commands.WithDraw(amount, _) -> handle_withdraw_creditline(amount, state)
    commands.Create(id, _, max_amount, business_product_id) ->
      handle_create_creditline(id, max_amount, business_product_id)
    commands.Block -> handle_block_creditline(state)
    commands.Close -> handle_close_creditline(state)
    commands.Activate -> handle_active_creditline(state)
  }
}
