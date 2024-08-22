import gleam/dynamic
import gleam/json.{type Json, float, object, string}
import lib/event_source/model/event
import lib/utils/date_utils.{utc_now_as_string}

pub type CreditLineEvent {
  Deposited(amount: Float, at: String)
  WithDrawn(amount: Float, at: String)
  Created(
    id: String,
    max_amount: Float,
    created_at: String,
    business_product_id: String,
  )
  Blocked(at: String)
  Closed(at: String)
  Actived(at: String)
}

pub fn build_deposited_event(
  id: String,
  amount: Float,
) -> event.DomainEvent(CreditLineEvent) {
  event.new(Deposited(amount: amount, at: utc_now_as_string()), "Deposited", id)
}

pub fn build_withdrawn_event(
  id: String,
  amount: Float,
) -> event.DomainEvent(CreditLineEvent) {
  event.new(WithDrawn(amount: amount, at: utc_now_as_string()), "WithDrawn", id)
}

pub fn build_created_event(
  id: String,
  max_amount: Float,
  business_product_id: String,
) -> event.DomainEvent(CreditLineEvent) {
  event.new(
    Created(
      id: id,
      max_amount: max_amount,
      created_at: utc_now_as_string(),
      business_product_id: business_product_id,
    ),
    "Created",
    id,
  )
}

pub fn build_blocked_event(id: String) -> event.DomainEvent(CreditLineEvent) {
  event.new(Blocked(at: utc_now_as_string()), "Blocked", id)
}

pub fn build_close_event(id: String) -> event.DomainEvent(CreditLineEvent) {
  event.new(Closed(at: utc_now_as_string()), "Closed", id)
}

pub fn build_activated_event(id: String) -> event.DomainEvent(CreditLineEvent) {
  event.new(Actived(at: utc_now_as_string()), "Actived", id)
}

pub fn credit_event_serializer(data: CreditLineEvent) -> Json {
  case data {
    Deposited(amount, at) ->
      object([#("amount", float(amount)), #("at", string(at))])
    WithDrawn(amount, at) ->
      object([#("amount", float(amount)), #("at", string(at))])
    Created(id, max_amount, created_at, business_product_id) ->
      object([
        #("id", string(id)),
        #("max_amount", float(max_amount)),
        #("created_at", string(created_at)),
        #("business_product_id", string(business_product_id)),
      ])
    Blocked(at) -> object([#("at", string(at))])
    Closed(at) -> object([#("at", string(at))])
    Actived(at) -> object([#("at", string(at))])
  }
}

pub fn credit_event_deserializer(
  event_name: String,
) -> dynamic.Decoder(CreditLineEvent) {
  case event_name {
    "Deposited" ->
      dynamic.decode2(
        Deposited,
        dynamic.field("amount", of: dynamic.float),
        dynamic.field("at", of: dynamic.string),
      )
    "WithDrawn" ->
      dynamic.decode2(
        WithDrawn,
        dynamic.field("amount", of: dynamic.float),
        dynamic.field("at", of: dynamic.string),
      )
    "Created" ->
      dynamic.decode4(
        Created,
        dynamic.field("id", of: dynamic.string),
        dynamic.field("max_amount", of: dynamic.float),
        dynamic.field("created_at", of: dynamic.string),
        dynamic.field("business_product_id", of: dynamic.string),
      )
    "Blocked" ->
      dynamic.decode1(Blocked, dynamic.field("at", of: dynamic.string))
    "Closed" -> dynamic.decode1(Closed, dynamic.field("at", of: dynamic.string))
    "Actived" ->
      dynamic.decode1(Actived, dynamic.field("at", of: dynamic.string))
    _ -> panic
  }
}
