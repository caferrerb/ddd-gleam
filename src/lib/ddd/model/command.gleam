import gleam/option.{type Option}

pub type CommandData

pub type CommandMetadata {
  CommandMetadata(
    occurred_at: String,
    correlation_id: String,
    causation_id: String,
  )
}

pub type Command(c) {
  Command(
    id: String,
    metadata: Option(CommandMetadata),
    data: c,
    name: String,
    aggregate_id: String,
  )
}
