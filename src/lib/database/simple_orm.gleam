import gleam/dynamic.{type Decoder, type Dynamic}
import gleam/int
import gleam/io
import gleam/json.{type Json, array, int, null, object, string}
import gleam/list
import gleam/option.{type Option, Some}
import gleam/pgo.{type Connection, type Value}
import gleam/string

pub type Register {
  Register(data: List(#(String, Value)))
}

pub type DatabaseError {
  DatabaseError(message: String)
}

type QueryBuildResult {
  QueryBuildResult(query: String, params: List(Value))
}

fn gen_idx(acc: List(String), total: Int, offset: Int) -> List(String) {
  case total {
    0 -> acc
    _ ->
      gen_idx(
        list.append(acc, ["$" <> int.to_string(total + offset - 1)]),
        total - 1,
        offset,
      )
  }
}

fn build_insert(table: String, registers: List(Register)) -> QueryBuildResult {
  case registers {
    [first, ..] -> {
      let data = first.data
      let columns =
        list.map(data, fn(value) {
          let #(name, _) = value
          name
        })
        |> string.join(",")

      let num_columns = list.length(data)
      let #(idxs, values, _) =
        list.fold(registers, #([], [], 1), fn(acc, reg) {
          let #(idx, values, offset) = acc
          let values =
            list.append(
              values,
              list.map(reg.data, fn(value_tup) {
                let #(_, value) = value_tup
                value
              }),
            )
          let ids =
            gen_idx([], num_columns, offset) |> list.reverse |> string.join(",")
          let idxs = list.append(idx, ["(" <> ids <> ")"])
          let offset = offset + num_columns
          #(idxs, values, offset)
        })

      let query =
        "INSERT INTO "
        <> table
        <> " ("
        <> columns
        <> " ) VALUES "
        <> string.join(idxs, ",")
      QueryBuildResult(query: query, params: values)
    }
    [] -> QueryBuildResult(query: "Nil", params: [])
  }
}

pub fn persist(
  table: String,
  registers: List(Register),
  connection: Connection,
) -> Result(List(Register), DatabaseError) {
  let query = build_insert(table, registers)
  let result =
    pgo.execute(query.query, connection, query.params, dynamic.dynamic)

  case result {
    Ok(_) -> Ok(registers)
    Error(e) -> {
      case e {
        pgo.PostgresqlError(code, name, message) -> {
          io.println_error(code <> name <> message)
          Error(DatabaseError(
            "PostgresqlError:" <> code <> ":" <> ":" <> name <> ":" <> message,
          ))
        }
        pgo.ConnectionUnavailable -> {
          io.println_error("ConnectionUnavailable")
          Error(DatabaseError("ConnectionUnavailable:"))
        }
        pgo.ConstraintViolated(e, g, f) -> {
          io.println_error("ConstraintViolated" <> e <> g <> f)
          Error(DatabaseError("ConstraintViolated" <> e <> g <> f))
        }
        pgo.UnexpectedArgumentCount(e, g) -> {
          Error(DatabaseError(
            "UnexpectedArgumentCount"
            <> int.to_string(e)
            <> "_"
            <> int.to_string(g),
          ))
        }
        pgo.UnexpectedArgumentType(e, g) -> {
          Error(DatabaseError("UnexpectedArgumentType---" <> e <> "_" <> g))
        }
        pgo.UnexpectedResultType(_) -> {
          io.println_error("UnexpectedResultType")
          Error(DatabaseError("UnexpectedResultType"))
        }
      }
    }
  }
}

pub fn find(
  table: String,
  projection_fields: List(String),
  predicates: List(#(String, Value)),
  row_type: Decoder(t),
  mapper: fn(Dynamic) -> List(d),
) -> Result(List(d), DatabaseError) {
  let init_query =
    "SELECT " <> string.join(projection_fields, ",") <> " FROM " <> table

  let query = case predicates {
    [_, ..] -> {
      let predicates_str =
        list.index_map(predicates, fn(pred, idx) {
          let #(name, _) = pred
          name <> "=$" <> int.to_string(idx + 1)
        })
        |> string.join(" AND ")
      init_query <> " WHERE " <> predicates_str
    }
    [] -> init_query
  }
  io.println(query)
  Ok([])
}
