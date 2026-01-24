# A native Zoxide-like implementation. Based from the following post:
# https://github.com/nushell/nushell/discussions/17232

use std/dirs
use ./utils.nu

# Prints the full path of the Nuzlocke database.
export def "db path" [] {
  $'($nu.data-dir? | default $'($env.HOME)/.local/share/nushell')/foodogsquared/nuzlocke.db'
}

# Create a query for the Nuzlocke database.
def "db query" --wrapped [...args: string]: [
  nothing -> any
  string -> any
] {
  open (db path) | query db ($in | default $args)
}

# Prints the default dataset for the Nuzlocke database.
#
# As of this writing, it simply adds the home directory and various XDG base
# directories.
def "db default_data" [] {
  [
    [ path, score, last_accessed ];
    [ $nu.home-path, 0.0, (date now) ]
  ] | utils optional ($env.XDG_DOCUMENTS_DIR? != null) [
    [ path, score, last_accessed ];
    [ $env.XDG_DOCUMENTS_DIR, 0.0, null ]
  ] | utils optional ($env.XDG_DOWNLOAD_DIR? != null) [
    [ path, score, last_accessed ];
    [ $env.XDG_DOWNLOAD_DIR, 0.0, null ]
  ] | utils optional ($env.XDG_PICTURES_DIR? != null) [
    [ path, score, last_accessed ];
    [ $env.XDG_PICTURES_DIR, 0.0, null ]
  ] | utils optional ($env.XDG_VIDEOS_DIR? != null) [
    [ path, score, last_accessed ];
    [ $env.XDG_VIDEOS_DIR, 0.0, null ]
  ] | utils optional ($env.XDG_MUSIC_DIR? != null) [
    [ path, score, last_accessed ];
    [ $env.XDG_MUSIC_DIR, 0.0, null ]
  ]
}

# Create the initial setup for the application.
def setup [] {
  let db = db path
  if not ($db | path exists) {
    mkdir ($db | path dirname)
    db default_data | into sqlite $db --table-name main

    db query r#'
      CREATE INDEX index_path_length ON main(length(path));
    '#
  }
}

# Add a path into the Nuzlocke database.
export def add [q: string]: [
  string -> any
  nothing -> any
] {
  db query r#'
    INSERT OR IGNORE INTO main (path) VALUES (?);
  '# --params ($in | default $q)
}

# Remove a path from the Nuzlocke database.
export def remove [q: string]: [
  string -> any
  nothing -> any
] {
  db query r#'
    DELETE FROM main WHERE path = ?
  '# --params ($in | default $q)
}

# Given a query, search for the matched directories in the database.
export def search [...q: string, --json] {
  if not (db path | path exists) { setup }

  db query r#'
    SELECT path FROM main WHERE path LIKE ? ORDER BY LENGTH(path) LIMIT 1
  '# --params  [$"%($q | str join '%')%"]
  | get 0.path --optional
}

# List all of the directories stored in the database.
export def list [--json] {
  if not (db path | path exists) { setup }

  db query r#'
    SELECT * FROM main ORDER BY score;
  '#
}

#export alias z = 
