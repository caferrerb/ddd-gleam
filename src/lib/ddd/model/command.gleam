import gleam/option.{type Option}

pub type CommandData

pub type CommandMetadata {
  Metadata(occurred_at: String, correlation_id: String, causation_id: String)
}

pub type Command(c) {
  Command(
    metadata: Option(CommandMetadata),
    data: c,
    name: String,
    aggregate_id: String,
  )
}
