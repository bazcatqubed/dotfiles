# Link files from the dotfiles directory to the given path. This is mostly used
# on projects that uses configuration ad-hoc such as Git hooks.
export def link-from [dotdir_path: string, path: string] {
  with-env {
    "FDS_DOTDIR": ($env.FDS_DOTDIR? | default $'($env.XDG_PROJECTS_DIR)/packages/dotfiles')
  } {
    ^ln --symbolic --force $'($env.FDS_DOTDIR)/($dotdir_path)' $path
  }
}

# Return the dotfiles directory.
export def main [] {
  $env.FDS_DOTDIR? | default $'($env.XDG_PROJECTS_DIR)/dotfiles'
}
