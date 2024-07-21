import app/account/domain/account_events.{
  type AccountEvent, account_event_data_to_json, account_event_to_json,
  account_event_to_string,
}
import gleam/io
import gleam/json.{type Json, array, int, null, object, string}
import gleam/list
import gleam/option.{type Option, None, Some}
import lib/ddd/model/error
import lib/ddd/model/event.{type Event}
import lib/es/event_store_client.{ESEvent}

pub fn get_account_events(
  aggregate: String,
  id: String,
) -> Result(Option(List(Event(AccountEvent))), error.DomainError) {
  io.debug("getting event for " <> aggregate <> "=" <> id)
  Ok(Some([]))
}

pub fn persist_account_events(
  aggregate: String,
  id: String,
  events: List(Event(AccountEvent)),
) -> Result(List(Event(AccountEvent)), error.DomainError) {
  io.debug("persisting event in " <> aggregate <> "=" <> id)
  list.fold(events, "", fn(_, event) {
    io.println(account_event_to_string(event) <> "<::>")
    ""
  })
  let events_to_persist =
    list.map(events, fn(event) {
      ESEvent(
        id: "",
        name: event.name,
        data: account_event_data_to_json(event.data),
        metadata: event.metdata_to_json(event),
        revision: event.unwrap_metadata(event.metadata).revision,
      )
    })
  case event_store_client.persist_events("gleam.accounts", events_to_persist) {
    Ok(_) -> Ok(events)
    Error(e) -> {
      io.print_error("errir" <> e.message)
      Error(error.DomainError("error saving events" <> e.message))
    }
  }
}
