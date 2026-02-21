# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# A native Zoxide-like implementation. Based from the following post:
# https://github.com/nushell/nushell/discussions/17232
#
# Basically an autojump reimplementation in Nushell.

use std/dirs
use ./utils.nu
use std/util [repeat]


# Prints the full path of the Nuzlocke database.
export def "config db-path" --env [] {
  $env.config.nuzlocke?.db-path?
  | default $env.FDS_NUZLOCKE_DB_PATH?
  | default $'($nu.data-dir? | default $'($env.HOME)/.local/share/nushell')/foodogsquared/nuzlocke.db'
}

export def "config exclude-paths" --env []: [
  nothing -> list<string>
] {
  $env.config.nuzlocke?.exclude-paths?
  | default $env.FDS_NUZLOCKE_EXCLUDE_PATHS?
  | default (config default-exclude-paths)
}

# Prints the default dataset for the Nuzlocke database.
#
# As of this writing, it simply adds the home directory and various XDG base
# directories.
def "config default-data" [] {
  utils optional list ($env.XDG_DOCUMENTS_DIR? != null) [ $env.XDG_DOCUMENTS_DIR ]
  | utils optional list ($env.XDG_DOWNLOAD_DIR? != null) [ $env.XDG_DOWNLOAD_DIR ]
  | utils optional list ($env.XDG_PICTURES_DIR? != null) [ $env.XDG_PICTURES_DIR ]
  | utils optional list ($env.XDG_VIDEOS_DIR? != null) [ $env.XDG_VIDEOS_DIR ]
  | utils optional list ($env.XDG_MUSIC_DIR? != null) [ $env.XDG_MUSIC_DIR ]
  | utils optional list ($env.XDG_DESKTOP_DIR? != null) [ $env.XDG_DESKTOP_DIR ]
  | utils optional list ($env.XDG_PUBLICSHARE_DIR? != null) [ $env.XDG_PUBLICSHARE_DIR ]
}

def "config default-exclude-paths" [] {
  [ $nu.home-dir ]
  | utils optional list ($env.XDG_STATE_HOME? != null) [ $env.XDG_STATE_HOME ]
  | utils optional list ($env.XDG_CACHE_HOME? != null) [ $env.XDG_CACHE_HOME ]
  | utils optional list ($env.XDG_RUNTIME_DIR? != null) [ $env.XDG_RUNTIME_DIR ]
}

# Create the initial setup for the application.
export def setup [] {
  let db = config db-path
  if not ($db | path exists) {
    mkdir ($db | path dirname)

    let db_initial_script = r#'
      BEGIN;
      CREATE TABLE [main] (
        'path' TEXT UNIQUE NOT NULL,
        'score' REAL NOT NULL DEFAULT 0.0,
        'last_accessed' DATETIME DEFAULT (datetime('now', 'localtime'))
      ) STRICT;

      -- Make a covering index because why not.
      CREATE INDEX idx_path ON main(length(path), path, last_accessed);
    '#

    let initial_data_script = config default-data
      | each { |$o| $"INSERT INTO \"main\" \(path\) VALUES\('($o)'\);" }
      | str join "\n"

    # Well, I'm just sick of making this to open it again and again since
    # Nushell doesn't allow multiple statements in one query.
    ^sqlite3 $db ($db_initial_script + $initial_data_script + "COMMIT;")
  }
}

# Return the score as basis for sorting. This is only based from the last
# accessed field for now.
def "dir score" [p: record] {
  let d: duration = (date now) - ($p.last_accessed |  date from-human)

  if ($d < 1hr) {
    $p.score * 4
  } else if ($d < 1day) {
    $p.score * 2
  } else if ($d < 3day) {
    $p.score * 1.5
  } else if ($d < 1wk) {
    $p.score * 0.5
  } else {
    $p.score * 0.25
  }
}

# Add a path or increment its rank into the Nuzlocke database.
export def add [...paths: string,
  --score: float = 0.1, # Score to be added to the given directories.
]: [
  list<string> -> table
  nothing -> table
] {
  let exclude_paths = config exclude-paths
  let paths: list<string> = $in | default $paths | each { |p| utils dir sanitize $p } | where { |p| $p not-in $exclude_paths }

  $paths | each { |p| {
    if not ($p | path exists) {
      error make {
        msg: "Given path does not exist."
        label: {
          text: ("given path is in " + $p)
          span: (metadata $p).span
        }
      }
    }

    if ($p | path type) != "dir" {
      error make {
        msg: "Given path is not a directory."
      }
    }
  } }

  if ($paths | is-empty) {
    return {}
  }

  if not (config db-path | path exists) { setup }

  open (config db-path) | query db (r#'
    INSERT OR IGNORE INTO main (path) VALUES '# + ("(?)" | repeat ($paths | length) | str join ",") + r#'
    ON CONFLICT(path) DO UPDATE SET score=score + ?, last_accessed = (datetime('now', 'localtime'))
    WHERE '# + ("path = ?" | repeat ($paths | length) | str join "OR ") + r#'
    RETURNING *;
  '#) --params ($paths ++ [ $score ] ++ $paths)
}

# Remove a path from the Nuzlocke database.
export def remove [...paths: string@dirs-context]: [
  list<string> -> table
  nothing -> table
] {
  if not (config db-path | path exists) { setup }

  let paths: list<string> = $in | default $paths | each { |p| $p | utils dir sanitize }
  let db_script = "DELETE FROM main WHERE " + ("path = ?" | repeat ($paths | length) | str join "OR ") + " RETURNING *"

  open (config db-path) | query db $db_script --params $paths
}

# Given a query, search for the matched directories in the database.
export def query [...q: string,
  --limit: int = 10, # How many entries to be shown.
] {
  if not (config db-path | path exists) { setup }

  let query = $q | where {|it| ($it | path expand) != $it }
  let paths = $q | where {|it| ($it | path expand) == $it }

  if $q == [] {
    return (main)
  }

  try {
    mut params = [ $env.PWD ]

    if ($query | length) > 0 {
      $params ++= [ $"%($query | str join '%')%" ]
    }

    if ($paths | length) > 0 {
      $params ++= $paths
    }

    $params ++= [ $limit ]

    let db_query = (r#'
      SELECT * FROM main WHERE path != ? AND ('#
      + (if ($query | length) > 0 { "path LIKE ? " } else { "" })
      + (if (($query | length) > 0) and (($paths | length) > 0) { "OR " } else { "" })
      + ("path = ?" | repeat ($paths | length) | str join "OR ")
      + r#') ORDER BY
        score DESC, last_accessed DESC, LENGTH(path)
        LIMIT ?
    '#)

    open (config db-path) | query db $db_query --params $params
  } catch { |_| return null }
}

# Convenience function around `query` for getting paths.
export def search --wrapped [...args] {
  query ...$args | get path | default null
}

# List all of the directories stored in the database.
export def main [] {
  if not (config db-path | path exists) { setup }

  let data = open (config db-path) | query db r#'
    SELECT * FROM main ORDER BY score DESC, last_accessed DESC;
  '#

  $data | each { |dir|
    $dir
    | update last_accessed { $in | into datetime }
  }
}
export alias list = main

def dirs-context [] {
  {
    options: {
      case_sensitive: false,
      completion_algorithm: substring,
      sort: false,
    },
    completions: (list | get path)
  }
}

# Go to the nearest match as the working directory.
export def jump --env [...q: string@dirs-context] {
  let path = search ...$q

  if $path == null {
    error make { msg: "no match found" }
  }

  match $q {
    [] => { cd ~ }
    [ "-" ] => { cd - }
    _ => { dirs add ...$path }
  }
}

# Reset the database.
export def reset [] {
  rm (config db-path)
  db setup
}

# Remove paths in the database that no longer exists.
export def gc [] {
  let nonexisting_paths = list | where { not ($in.path | path exists) }

  if ($nonexisting_paths | length) <= 0 {
    return
  }

  let db_script = "DELETE FROM main WHERE path = " + ("?" | repeat ($nonexisting_paths | length) | str join ", ") + " RETURNING *"

  open (config db-path)
  | query db $db_script --params ($nonexisting_paths | get path)
}
