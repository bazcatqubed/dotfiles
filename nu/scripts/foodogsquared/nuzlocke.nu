# A native Zoxide-like implementation. Based from the following post:
# https://github.com/nushell/nushell/discussions/17232
#
# Basically an autojump reimplementation in Nushell.

use std/dirs
use ./utils.nu
use std/util [repeat]


# Prints the full path of the Nuzlocke database.
export def "db path" [] {
  $'($nu.data-dir? | default $'($env.HOME)/.local/share/nushell')/foodogsquared/nuzlocke.db'
}

# Prints the default dataset for the Nuzlocke database.
#
# As of this writing, it simply adds the home directory and various XDG base
# directories.
def "db default-data" [] {
  utils optional ($env.XDG_DOCUMENTS_DIR? != null) [ $env.XDG_DOCUMENTS_DIR ]
  | utils optional ($env.XDG_DOWNLOAD_DIR? != null) [ $env.XDG_DOWNLOAD_DIR ]
  | utils optional ($env.XDG_PICTURES_DIR? != null) [ $env.XDG_PICTURES_DIR ]
  | utils optional ($env.XDG_VIDEOS_DIR? != null) [ $env.XDG_VIDEOS_DIR ]
  | utils optional ($env.XDG_MUSIC_DIR? != null) [ $env.XDG_MUSIC_DIR ]
  | utils optional ($env.XDG_DESKTOP_DIR? != null) [ $env.XDG_DESKTOP_DIR ]
}

# Create the initial setup for the application.
export def setup [] {
  let db = db path
  if not ($db | path exists) {
    mkdir ($db | path dirname)

    let db_initial_script = r#'
      BEGIN;
      CREATE TABLE [main] (
        'path' TEXT UNIQUE NOT NULL,
        'score' REAL NOT NULL DEFAULT 0.0,
        'last_accessed' DATETIME DEFAULT (datetime('now', 'localtime'))
      );

      -- Make a covering index because why not.
      CREATE INDEX index_path_length ON main(length(path), path, last_accessed);
    '#

    let initial_data_script = db default-data
      | each { |$o| $"INSERT INTO \"main\" \(path\) VALUES\('($o)'\);" }
      | str join "\n"

    # Well, I'm just sick of making this to open it again and again since
    # Nushell doesn't allow multiple statements in one query.
    sqlite3 $db ($db_initial_script + $initial_data_script + "COMMIT;")
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
export def add [path?: string]: [
  string -> any
  nothing -> any
] {
  if $in == null and $path == null {
    error make { msg: "No input was given." }
  }

  let path = $in | default $path
  if not ($path | path exists) {
    error make {
      msg: "Given path does not exist."
      label: {
        text: ("given path is in " + $path)
        span: (metadata $path).span
      }
    }
  }

  if not (($path | path type) == "dir") {
    error make {
      msg: "Given path is not a directory."
    }
  }

  if not (db path | path exists) { setup }

  open (db path) | query db r#'
    INSERT OR IGNORE INTO main (path) VALUES (:p)
    ON CONFLICT(path) DO UPDATE SET score=score + 0.01, last_accessed = (datetime('now', 'localtime'))
    WHERE path = :p
    RETURNING *;
  '# --params { p: ($path | utils dir sanitize) }
}

# Remove a path from the Nuzlocke database.
export def remove [q?: string@dirs-context]: [
  string -> any
  nothing -> any
] {
  if $in == null and $q == null {
    error make { msg: "No input was given." }
  }

  if not (db path | path exists) { setup }

  let path = $in | default $q | dir sanitize
  open (db path) | query db "DELETE FROM main WHERE path = ? RETURNING *" --params [ $path ]
}

# Given a query, search for the matched directories in the database.
export def search [...q: string,
  --limit: int = 10, # How many entries to be shown.
] {
  if not (db path | path exists) { setup }

  try {
    open (db path) | query db r#'
      SELECT path FROM main WHERE path LIKE ? AND path != ? ORDER BY
        score DESC, last_accessed DESC, LENGTH(path)
        LIMIT ?
    '# --params  [$"%($q | str join '%')%", $env.PWD, $limit]
    | get path
  } catch { |_| return null }
}

# List all of the directories stored in the database.
export def list [] {
  if not (db path | path exists) { setup }

  let data = open (db path) | query db r#'
    SELECT * FROM main ORDER BY score DESC, last_accessed DESC;
  '#

  $data | each { |dir|
    $dir
    | update score { (dir score $dir) }
    | update last_accessed { $in | into datetime }
  }
}
export alias ls = list

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
  rm (db path)
  db setup
}

# Remove paths in the database that no longer exists.
export def gc [] {
  let nonexisting_paths = list | where { not ($in.path | path exists) }

  if ($nonexisting_paths | length) <= 0 {
    return
  }

  let db_script = "DELETE FROM main WHERE path = " + ("?" | repeat ($nonexisting_paths | length) | str join ", ") + " RETURNING *"

  open (db path)
  | query db $db_script --params ($nonexisting_paths | get path)
}
