import app/creditline/business/model/creditline.{CreditLine}
import gleam/option.{type Option, None, Some}
import lib/ddd/model/command.{type CommandMetadata, CommandMetadata}
import lib/utils/date_utils.{utc_now_as_string}
import youid/uuid

pub type CreditLineCommand {
  Deposit(amount: Float, at: String)
  WithDraw(amount: Float, at: String)
  Create(id: String, at: String, max_amount: Float, business_product_id: String)
  Block
  Close
  Activate
}

fn build_metadata() -> CommandMetadata {
  CommandMetadata(
    occurred_at: utc_now_as_string(),
    correlation_id: "N/D",
    causation_id: "N/D",
  )
}

pub fn build_deposit_cmd(
  id: String,
  amount: Float,
) -> command.Command(CreditLineCommand) {
  command.Command(
    id: uuid.v4_string(),
    metadata: Some(build_metadata()),
    data: Deposit(at: utc_now_as_string(), amount: amount),
    aggregate_id: id,
    name: "Deposit",
  )
}

pub fn build_withdraw_cmd(
  id: String,
  amount: Float,
) -> command.Command(CreditLineCommand) {
  command.Command(
    id: uuid.v4_string(),
    metadata: Some(build_metadata()),
    data: WithDraw(at: utc_now_as_string(), amount: amount),
    aggregate_id: id,
    name: "WithDraw",
  )
}

pub fn build_create_cmd(
  id: String,
  max_amount: Float,
  business_product_id: String,
) -> command.Command(CreditLineCommand) {
  command.Command(
    id: uuid.v4_string(),
    metadata: Some(build_metadata()),
    data: Create(
      id: id,
      at: utc_now_as_string(),
      max_amount: max_amount,
      business_product_id: business_product_id,
    ),
    aggregate_id: id,
    name: "WithDraw",
  )
}

pub fn build_block_cmd(id: String) -> command.Command(CreditLineCommand) {
  command.Command(
    id: uuid.v4_string(),
    metadata: Some(build_metadata()),
    data: Block,
    aggregate_id: id,
    name: "Block",
  )
}

pub fn build_close_cmd(id: String) -> command.Command(CreditLineCommand) {
  command.Command(
    id: uuid.v4_string(),
    metadata: Some(build_metadata()),
    data: Close,
    aggregate_id: id,
    name: "Close",
  )
}

pub fn build_active_cmd(id: String) -> command.Command(CreditLineCommand) {
  command.Command(
    id: uuid.v4_string(),
    metadata: Some(build_metadata()),
    data: Activate,
    aggregate_id: id,
    name: "Activate",
  )
}
