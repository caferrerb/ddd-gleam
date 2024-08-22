import app/creditline/application/repositories/creditline_es_repo.{
  get_creditline, save_creditline_events,
}
import app/creditline/business/model/commands.{
  type CreditLineCommand, build_active_cmd, build_block_cmd, build_close_cmd,
  build_create_cmd, build_deposit_cmd, build_withdraw_cmd,
}
import app/creditline/business/model/creditline.{type CreditLine}
import app/creditline/business/model/events.{type CreditLineEvent}
import app/creditline/business/service/command_handlers.{command_handler}
import app/creditline/business/service/events_reducer.{
  credit_line_events_reducer,
}
import lib/ddd/application/aggregate_root.{
  type DomainError, Aggregate, mutate_aggregate,
}

pub fn new() -> aggregate_root.Aggregate(
  CreditLine,
  CreditLineEvent,
  CreditLineCommand,
) {
  Aggregate(
    "gleam.accounts",
    command_handler,
    get_creditline,
    fn(_, _, state) { Ok(state) },
    save_creditline_events,
    credit_line_events_reducer,
  )
}

pub fn create_creditline(
  aggr: aggregate_root.Aggregate(CreditLine, CreditLineEvent, CreditLineCommand),
  id: String,
  bp_id: String,
  max_amount: Float,
) -> Result(CreditLine, DomainError) {
  let result = mutate_aggregate(aggr, build_create_cmd(id, max_amount, bp_id))
  case result {
    Ok(mut) -> {
      let state = mut.state
      Ok(state.data)
    }
    Error(error) -> Error(error)
  }
}

pub fn deposit_creditline(
  aggr: aggregate_root.Aggregate(CreditLine, CreditLineEvent, CreditLineCommand),
  id: String,
  amount: Float,
) -> Result(CreditLine, DomainError) {
  let result = mutate_aggregate(aggr, build_deposit_cmd(id, amount))
  case result {
    Ok(mut) -> {
      let state = mut.state
      Ok(state.data)
    }
    Error(error) -> Error(error)
  }
}

pub fn withdraw_creditline(
  aggr: aggregate_root.Aggregate(CreditLine, CreditLineEvent, CreditLineCommand),
  id: String,
  amount: Float,
) -> Result(CreditLine, DomainError) {
  let result = mutate_aggregate(aggr, build_withdraw_cmd(id, amount))
  case result {
    Ok(mut) -> {
      let state = mut.state
      Ok(state.data)
    }
    Error(error) -> Error(error)
  }
}

pub fn block_creditline(
  aggr: aggregate_root.Aggregate(CreditLine, CreditLineEvent, CreditLineCommand),
  id: String,
) -> Result(CreditLine, DomainError) {
  let result = mutate_aggregate(aggr, build_block_cmd(id))
  case result {
    Ok(mut) -> {
      let state = mut.state
      Ok(state.data)
    }
    Error(error) -> Error(error)
  }
}

pub fn close_creditline(
  aggr: aggregate_root.Aggregate(CreditLine, CreditLineEvent, CreditLineCommand),
  id: String,
) -> Result(CreditLine, DomainError) {
  let result = mutate_aggregate(aggr, build_close_cmd(id))
  case result {
    Ok(mut) -> {
      let state = mut.state
      Ok(state.data)
    }
    Error(error) -> Error(error)
  }
}

pub fn active_creditline(
  aggr: aggregate_root.Aggregate(CreditLine, CreditLineEvent, CreditLineCommand),
  id: String,
) -> Result(CreditLine, DomainError) {
  let result = mutate_aggregate(aggr, build_active_cmd(id))
  case result {
    Ok(mut) -> {
      let state = mut.state
      Ok(state.data)
    }
    Error(error) -> Error(error)
  }
}
