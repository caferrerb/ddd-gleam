import gleam/option.{type Option}
import lib/ddd/model/error
import lib/ddd/model/state.{type State}

pub type StateStorePersistFn(s) =
  fn(String, State(s)) -> Result(State(s), error.DomainError)

pub type StateStoreGetFn(s) =
  fn(String, String) -> Result(Option(State(s)), error.DomainError)
