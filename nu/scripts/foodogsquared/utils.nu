# A set of utilities shared among my modules.

# Append the list with the given value if the given condition has been
# fulfilled.
export def optional [cond: bool, val: list, init?: list = [ ] ]: [
  list -> list
  nothing -> list
] {
  let d = $in | default $init
  if $cond {
    $d | append $val
  } else {
    $d
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

# Clean up the given directory.
export def "dir sanitize" [q?: string]: [
  string -> string
  nothing -> string
] {
  ($in | default $q) | path expand | str trim --right --char '/'
}

export const MONTH_DURATION: duration = 1day * 30
export const YEAR_DURATION: duration = 1wk * 52
