# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# A bunch of Git-related utilites to be easily used with Nushell.

# List all of the ignored files by Git.
export def list-ignored --wrapped [...paths: string,
  --all
] {
  let paths = match $all {
    true => (glob **)
    false => $paths
  }

  ^git check-ignore ...$paths | lines
}

# List all of the files recognized by Git.
export def list-files --wrapped [...paths: string] {
  ^git ls-files ...$paths | lines
}

# View logs from a given Git object.
export def log --wrapped [...rest: string] {
  ^git log --pretty="%s\t%H\t%aI\t%aN\t%aE" -- ...$rest
  | lines | split column "\t" subject hash date author email
}
