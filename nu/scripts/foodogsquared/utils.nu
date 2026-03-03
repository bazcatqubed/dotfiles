# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# A set of utilities shared among my modules.

# Append the list with the given value if the given condition has been
# fulfilled.
export def "optional list" [cond: bool, val: list, init?: list = [ ] ]: [
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

# Append the string with the given value if the given condition has been
# fulfilled.
export def "optional string" [cond: bool, val: string, init?: string = "" ]: [
  string -> string
  nothing -> string
] {
  let v = $in | default $init
  if $cond {
    $v + $val
  } else {
    $v
  }
}

# Increase input value by the given amount.
@example "Increase by 5." {
  7 | increment 5
} --result 12
export def increment [amount: int = 1]: int -> int {
  $in + $amount
}

# Decrease input value by the given amount.
@example "Decrease by 10." {
  19 | decrement 10
} --result 9
export def decrement [amount: int = 1]: int -> int {
  $in - $amount
}

# Clean up the given directory.
@example "apply to a relative directory" {
  dir sanitize ./mod.nu
} --result "/home/foo-dogsquared/Documents/nushell/mod.nu"
@example "apply to an absolute directory" {
  dir sanitize /home/foo-dogsquared/Documents/nushell/lib/
} --result "/home/foo-dogsquared/Documents/nushell/lib"
@example "apply through stdin" {
  "./README.adoc" | dir sanitize
} --result "/home/foo-dogsquared/Documents/nushell/README.adoc"
export def "dir sanitize" [q?: string]: [
  string -> string
  nothing -> string
] {
  ($in | default $q) | path expand | str trim --right --char '/'
}

# Set the value between the given boundary.
export def clamp [min: int, max: int, value?: int]: [
  int -> int
  nothing -> int
] {
  let value = $in | default $value
  let max = [ $value $min ] | math max

  [ $max $min ] | math min
}

# Map the output given a set of values.
export def interpolate [a: float, b: float, value?: float]: [
  float -> float
  nothing -> float
] {
  ((1 - $value) * $a) + ($value * $b)
}

# A common converter function for environment variables that typically deals
# with search paths that are delimited by a common character (e.g., `PATH` as a
# colon-delimited list of paths).
export def "search-paths common-converter" [delimiter: string = ':'] {
  {
    from_string: { |s| $s | split row $delimiter }
    to_string: { |s| $s | str join $delimiter }
  }
}

# Given a list of paths, list all existing files under the common given
# subpath.
export def "search-paths find" [subpath: string, ...search_paths: string]: [
  list<string> -> list<string>
  nothing -> list<string>
] {
  ($in | default $search_paths) | each { |p| try { ls $"($p)/($subpath)" } } | flatten
}

# List all of the existing top-level files in all search paths.
export def "search-paths list" [...search_paths: string]: [
  list<string> -> table
  nothing -> table
] {
  ($in | default $search_paths) | each { |p| try { ls $p } } | flatten
}

export const MONTH_DURATION: duration = 1day * 30
export const YEAR_DURATION: duration = 1wk * 52
