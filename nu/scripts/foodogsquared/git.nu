# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# A bunch of Git-related utilites to be easily used with Nushell.

# List all of the ignored files by Git.
export def ls-ignored --wrapped [...paths: string,
  --all
] {
  let paths = match $all {
    true => (glob **)
    false => $paths
  }

  ^git check-ignore ...$paths | lines
}

# Returns a list of files that have changed in the current worktree.
export def what-files-have-changed [] {
  ^git diff-index --name-only HEAD | lines
}

# List all of the files recognized by Git.
export def ls-files --wrapped [...rest: string] {
  ^git ls-files ...$rest | lines
}

# View logs from a given Git object.
export def log --wrapped [...rest: string] {
  ^git log --pretty="%s\t%H\t%aI\t%aN\t%aE" -- ...$rest
  | lines | split column "\t" subject hash date author email
}

# Create the typical user string found in commits.
export def get-complete-user [] {
  $"(^git config user.name) <(^git config user.email)>"
}
