import app/creditline/business/model/creditline.{type CreditLine, new}
import app/creditline/business/model/events.{
  type CreditLineEvent, credit_event_deserializer,
}
import app/creditline/business/service/events_reducer.{
  credit_line_events_reducer,
}
import gleam/io
import lib/event_source/application/event_source.{
  type EventSourceError, State, persist_events,
}

import app/creditline/infraestructure/event_store_connection.{
  connect_to_event_store,
}
import lib/ddd/application/aggregate_root.{type DomainError, DomainError}
import lib/event_source/model/event.{type DomainEvent}

pub fn save_creditline_events(
  aggregate_name: String,
  aggregate_id: String,
  events: List(DomainEvent(CreditLineEvent)),
) -> Result(List(DomainEvent(CreditLineEvent)), DomainError) {
  case
    persist_events(
      aggregate_name,
      aggregate_id,
      events,
      events.credit_event_serializer,
      connect_to_event_store(),
    )
  {
    Ok(result) -> Ok(result)
    Error(error) -> Error(DomainError(message: error.message))
  }
}

pub fn get_creditline(
  aggregate_name: String,
  aggregate_id: String,
) -> Result(event_source.State(CreditLine), DomainError) {
  let state_result =
    event_source.get_state_from_events(
      aggregate_name,
      aggregate_id,
      credit_line_events_reducer,
      State(data: new("", 0.0, ""), revision: 0, id: aggregate_id),
      credit_event_deserializer,
      connect_to_event_store(),
    )

  case state_result {
    Ok(state) -> {
      io.debug(state.revision)
      Ok(state)
    }
    Error(error) -> Error(DomainError(message: error.message))
  }
}
