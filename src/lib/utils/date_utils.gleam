import tempo/datetime

pub fn utc_now_as_string() -> String {
  datetime.now_utc() |> datetime.to_string
}
