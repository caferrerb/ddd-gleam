import gleam/erlang/os
import gleam/int
import gleam/option
import gleam/pgo.{type Connection}

pub fn connect_to_event_store() -> Connection {
  case
    os.get_env("db_host"),
    os.get_env("db_password"),
    os.get_env("db_user"),
    os.get_env("db_name"),
    os.get_env("db_port")
  {
    Ok(db_host), Ok(db_password), Ok(db_user), Ok(db_name), Ok(db_port) -> {
      let port = case int.parse(db_port) {
        Ok(port) -> port
        Error(_) -> 6543
      }
      pgo.connect(
        pgo.Config(
          ..pgo.default_config(),
          host: db_host,
          password: option.Some(db_password),
          user: db_user,
          database: db_name,
          port: port,
          pool_size: 15,
        ),
      )
    }
    _, _, _, _, _ -> panic
  }
}
