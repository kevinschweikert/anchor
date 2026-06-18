pub type Currency {
  EUR
  USD
}

pub type Amount {
  Amount(Int)
}

pub fn new(amount: Int) -> Amount {
  Amount(amount)
}

pub fn zero() {
  Amount(0)
}

pub fn add(a: Amount, b: Amount) -> Amount {
  let Amount(a) = a
  let Amount(b) = b
  Amount(a + b)
}

pub fn subtract(a: Amount, b: Amount) -> Amount {
  let Amount(a) = a
  let Amount(b) = b
  Amount(a - b)
}

pub fn multiply(a: Amount, multiplier: Int) -> Amount {
  let Amount(a) = a
  Amount(a * multiplier)
}

pub fn percentage(a: Amount, percentage: Int) -> Amount {
  let Amount(a) = a
  Amount(a * percentage / 100)
}
