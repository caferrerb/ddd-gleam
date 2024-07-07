pub type Account {
  Account(credits: Float, debits: Float, id: String, available: Float)
}

pub fn new(id: String) -> Account {
  Account(credits: 0.0, debits: 0.0, id: id, available: 0.0)
}
