import app/creditline/application/creditline_aggregate.{
  active_creditline, block_creditline, close_creditline, create_creditline,
  deposit_creditline, withdraw_creditline,
}
import app/creditline/business/model/creditline.{to_string}
import dotenv_gleam
import gleam/io
import lib/ddd/application/aggregate_root.{type DomainError}
import youid/uuid

pub fn main() {
  dotenv_gleam.config()
  let cl_aggr = creditline_aggregate.new()
  let uuid = "1DFBEAC9-B9C5-4BE7-A8DB-46C70DC66F0F"
  //uuid.v4_string()

  //let cl = create_creditline(cl_aggr, uuid, "bp-id", 1000.1)
  //print_cl(cl)
  let cl = withdraw_creditline(cl_aggr, uuid, 100.3)
  print_cl(cl)

  let cl = deposit_creditline(cl_aggr, uuid, 50.7)
  print_cl(cl)
}

pub fn print_cl(res: Result(creditline.CreditLine, DomainError)) {
  case res {
    Ok(cl) -> {
      io.println(creditline.to_string(cl))
    }
    Error(error) -> {
      io.println_error(error.message)
      panic
    }
  }
}
