import gleam/json.{type Json, array, float, int, object, string}
import lib/utils/date_utils.{utc_now_as_string}

pub type CreditLineState {
  Open
  Closed
  Blocked
}

pub type CreditLine {
  CreditLine(
    max_amount: Float,
    balance: Float,
    available: Float,
    id: String,
    used_amount: Float,
    created_at: String,
    state: CreditLineState,
    business_product_id: String,
    updated_at: String,
  )
}

pub fn new(
  id: String,
  max_amount: Float,
  business_product_id: String,
) -> CreditLine {
  CreditLine(
    id: id,
    max_amount: max_amount,
    balance: max_amount,
    available: max_amount,
    used_amount: 0.0,
    created_at: utc_now_as_string(),
    business_product_id: business_product_id,
    state: Open,
    updated_at: utc_now_as_string(),
  )
}

pub fn credit_line_state_to_string(state: CreditLineState) -> String {
  case state {
    Open -> "open"
    Closed -> "closed"
    Blocked -> "blocked"
  }
}

pub fn string_to_credit_line_state(state: String) -> CreditLineState {
  case state {
    "Open" -> Open
    "Closed" -> Closed
    "Blocked" -> Blocked
    _ -> panic
  }
}

pub fn to_json(cl: CreditLine) -> Json {
  object([
    #("id", string(cl.id)),
    #("state", string(credit_line_state_to_string(cl.state))),
    #("max_amount", float(cl.max_amount)),
    #("balance", float(cl.balance)),
    #("available", float(cl.available)),
    #("used_amount", float(cl.used_amount)),
    #("created_at", string(cl.created_at)),
    #("updated_at", string(cl.updated_at)),
    #("business_product_id", string(cl.business_product_id)),
  ])
}

pub fn to_string(cl: CreditLine) -> String {
  to_json(cl) |> json.to_string
}
