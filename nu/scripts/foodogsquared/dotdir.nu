# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# Link files from the dotfiles directory to the given path. This is mostly used
# on projects that uses configuration ad-hoc such as Git hooks.
export def link-from [
  dotdir_path: string@"context file-from-dotdir", # The path relative to the dotdir.
  path: string # The output path.
] {
  ^ln --symbolic --force $'(main)/($dotdir_path)' $path
}

def "context file-from-dotdir" [context: string] {
  {
    options: {
      case_sensitive: false,
      completion_algorithm: substring,
      sort: false,
    },
    completions: (glob $"(main)/**/*" --exclude [ **/.git/** **/.jj/** ] | each { $in | path relative-to (main) })
  }
}

# Return the dotfiles directory.
export def main --env [] {
  $env.foodogsquared?.dotdir?
  | default $env.FDS_DOTDIR?
  | default $'($env.XDG_PROJECTS_DIR)/dotfiles'
}
export alias config-dir = main
