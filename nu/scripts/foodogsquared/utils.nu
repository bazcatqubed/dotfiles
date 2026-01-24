# A set of utilities shared among my modules.

# Append the list with the given value if the given condition has been
# fulfilled.
export def optional [cond: bool, val: list]: list -> list {
  if $cond {
    $in | append $val
  } else {
    $in
  }
}

# Increase input value by the given amount.
export def increment [amount: int = 1]: int -> int {
  $in + $amount
}

# Decrease input value by the given amount.
export def decrement [amount: int = 1]: int -> int {
  $in - $amount
}
