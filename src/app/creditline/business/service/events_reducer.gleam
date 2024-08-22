import app/creditline/business/model/creditline.{
  type CreditLine, Blocked, CreditLine,
}
import app/creditline/business/model/events.{type CreditLineEvent}
import lib/event_source/application/event_source.{type EventSourceError}

pub fn credit_line_events_reducer(
  data: CreditLineEvent,
  creditline: CreditLine,
) -> Result(CreditLine, EventSourceError) {
  case data {
    events.Deposited(amount, at) -> {
      let new_balance = creditline.balance +. amount
      let new_available = creditline.available +. amount
      let new_used = creditline.max_amount -. new_balance
      Ok(
        CreditLine(
          ..creditline,
          balance: new_balance,
          available: new_available,
          used_amount: new_used,
          updated_at: at,
        ),
      )
    }
    events.WithDrawn(amount, at) -> {
      let new_balance = creditline.balance -. amount
      let new_available = creditline.available -. amount
      let new_used = creditline.max_amount -. new_balance
      Ok(
        CreditLine(
          ..creditline,
          balance: new_balance,
          available: new_available,
          used_amount: new_used,
          updated_at: at,
        ),
      )
    }
    events.Created(id, max_amount, _, business_product_id) -> {
      Ok(creditline.new(id, max_amount, business_product_id))
    }
    events.Blocked(at) -> {
      Ok(CreditLine(..creditline, state: creditline.Blocked, updated_at: at))
    }
    events.Closed(at) -> {
      Ok(CreditLine(..creditline, state: creditline.Closed, updated_at: at))
    }
    events.Actived(at) -> {
      Ok(CreditLine(..creditline, state: creditline.Open, updated_at: at))
    }
  }
}
