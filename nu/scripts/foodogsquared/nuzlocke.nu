# A independent native [autojump-like](https://github.com/wting/autojump)
# implementation in Nushell. As such, it has its own database schema as well as
# native integration all within Nushell.
#
# Nuzlocke expects its configuration value to be set at `$env.config.nuzlocke`
# namespace.
#
# As of 2026-02-23, it expects the following config keys:
#
# - `$env.config.nuzlocke.db-path` is a path where the database will be stored
# for various operations (e.g., querying for paths).
#
# - `$env.config.nuzlocke.exclude-paths` is a table of paths where Nuzlocke
# deny any paths listed here. For now, it is a table with the following schema:
# ** `dir` is the path to be excluded and it is **required**.
# ** `exact` tells whether the given path is only considered or any of the subpath.
#
# Based from the following post:
# https://github.com/nushell/nushell/discussions/17232

# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

use std/dirs
use ./utils.nu ['optional list' 'dir sanitize' 'search-paths common-converter']
use std/util [repeat]


# Prints the full path of the Nuzlocke database.
export def "config db-path" --env [] {
  $env.foodogsquared?.nuzlocke?.db_path?
  | default $env.FDS_NUZLOCKE_DB_PATH?
  | default $'($nu.data-dir? | default $'($env.HOME)/.local/share/nushell')/foodogsquared/nuzlocke.db'
}

export def "config exclude-paths" --env []: [
  nothing -> table
] {
  $env.foodogsquared?.nuzlocke?.exclude_paths?
  | default $env.FDS_NUZLOCKE_EXCLUDE_PATHS?
  | default (config default-exclude-paths)
  | config normalize-exclude-paths
}

# Returns the default dataset for the Nuzlocke database.
#
# As of this writing, it simply adds the home directory and various XDG base
# directories.
def "config default-data" [] {
  optional list ($env.XDG_DOCUMENTS_DIR? != null) [ $env.XDG_DOCUMENTS_DIR ]
  | optional list ($env.XDG_DOWNLOAD_DIR? != null) [ $env.XDG_DOWNLOAD_DIR ]
  | optional list ($env.XDG_PICTURES_DIR? != null) [ $env.XDG_PICTURES_DIR ]
  | optional list ($env.XDG_VIDEOS_DIR? != null) [ $env.XDG_VIDEOS_DIR ]
  | optional list ($env.XDG_MUSIC_DIR? != null) [ $env.XDG_MUSIC_DIR ]
  | optional list ($env.XDG_DESKTOP_DIR? != null) [ $env.XDG_DESKTOP_DIR ]
  | optional list ($env.XDG_PUBLICSHARE_DIR? != null) [ $env.XDG_PUBLICSHARE_DIR ]
}

# The reasonable default list of exclude paths.
export def "config default-exclude-paths" --env [] {
  [ { dir: $nu.home-dir, exact: true } ]
  | optional list ($env.XDG_STATE_HOME? != null) [ $env.XDG_STATE_HOME ]
  | optional list ($env.XDG_CACHE_HOME? != null) [ $env.XDG_CACHE_HOME ]
  | optional list ($env.XDG_RUNTIME_DIR? != null) [ $env.XDG_RUNTIME_DIR ]
}

# Normalize the given exclusion list. As an implementation detail, this simply
# converts a string (mainly used for convenience) into the correct schema.
export def "config normalize-exclude-paths" []: [
  list -> table
  table -> table
] {
  $in | each { |p|
    let t = $p | describe

    if $t == "string" {
      { dir: $p }
    } else $p
  }
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
        'last_accessed' TEXT DEFAULT (datetime('now', 'localtime'))
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

# See if the given path is excluded from the blocklist. If no input is given,
# it will automatically retrieve the exclude paths from `config exclude-paths`.
def "dir is-excluded" [
  p: string # The given path.
]: [
  table -> bool
  nothing -> bool
] {
  let exclude_paths = $in | default (config exclude-paths)

  $exclude_paths | any { |e|
    if ($e.exact? | default false) {
      $e.dir == $p
    } else {
      $p | str starts-with $e.dir
    }
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
  let paths: list<string> = $in | default $paths | each { |p| dir sanitize $p } | where { |p|
    not ($exclude_paths | dir is-excluded $p)
  }

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
    ON CONFLICT(path) DO UPDATE SET score=ROUND(score + ?, 2), last_accessed = (datetime('now', 'localtime'))
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

  let paths: list<string> = $in | default $paths | each { |p| $p | dir sanitize }
  let db_script = "DELETE FROM main WHERE " + ("path = ?" | repeat ($paths | length) | str join "OR ") + " RETURNING *"

  open (config db-path) | query db $db_script --params $paths
}

# Given a query, search for the matched directories in the database.
export def query [...q: string,
  --limit: int = 10, # How many entries to be shown.
] {
  if not (config db-path | path exists) { setup }

  let q = $q

  let query = $q | where {|it| ($it | path expand) != $it }
  let paths = $q | where {|it| ($it | path expand) == $it }

  if $q == [] {
    return (list)
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

    open (config db-path) | query db $db_query --params $params | normalize
  } catch { |_| return null }
}

# Convenience function around `query` for getting paths.
export def search --wrapped [...args] {
  query ...$args | get path | default null
}

# List all of the directories stored in the database.
export def list [
  --link # Skip making OSC7 hyperlinks.
] {
  if not (config db-path | path exists) { setup }

  let data = open (config db-path) | query db r#'
    SELECT * FROM main ORDER BY score DESC, last_accessed DESC;
  '#

  $data | normalize | if $link {
    $in | each { |i| $i | update path { $in | ansi link } }
  } else { $in }
}

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

# Given a result of a database query, normalize the data for Nushell version.
def normalize []: [
  table -> table
] {
  $in | each { |dir|
    $dir
    | update last_accessed { $in | into datetime }
  }
}

export-env {
  $env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge deep --strategy=append {
    FDS_NUZLOCKE_EXCLUDE_PATHS: {
      from_string: { $in | from json | config normalize-exclude-paths },
      to_string: { $in | config normalize-exclude-paths | to json },
    }
  }

  $env.config.hooks.env_change = $env.config.hooks.env_change | merge deep --strategy=append {
    PWD: [
      { |before, after| add $after }
    ]
  }
}
