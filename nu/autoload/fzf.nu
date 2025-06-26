# SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# Nushell module based from the `fzf --bash` output.
#
# This port takes some liberty from the Bash script and does not have the same
# integrations such as tmux for now.
#
# It accepts the following envvars and their following description:
#
# - FZF_TMUX_HEIGHT should be the height of the prompt interface and mainly
# used in considering for opening inside of tmux env.
# - FZF_CTRL_T_COMMAND is the default command for Ctrl+T keybinding set for
# this Nu script.
# - FZF_DEFAULT_OPTS contains default arguments to be passed to fzf when
# executing.
# - FZF_ALT_{,SHIFT_}C_COMMAND contains the executable and its arguments used for
# entering directories (with Alt+C and Alt+Shift+C keybinding, respectively).
#
# Note that most of the values from their respective variables are converted
# over from what would how fzf normally expects it to be.

use std/dirs

let __fzf_defaults = [
    --height ($env.FZF_TMUX_HEIGHT? | default "40%")
    --bind=ctrl-z:ignore
    --reverse
]

let envconvert_cmdstring = {
    from_string: { |s| $s | split row ' ' }
    to_string: { |s| $s | str join ' ' }
}

# Invoke fzf with default options.
def __fzf_select --env --wrapped [...rest: string] {
    with-env {
        FZF_CTRL_T_COMMAND: ($env.FZF_CTRL_T_COMMAND? | default "fzf")
        FZF_DEFAULT_OPTS: ($env.FZF_DEFAULT_OPTS? | default $__fzf_defaults)
    } {
        fzf ...$rest ...$env.FZF_DEFAULT_OPTS
    }
}

# Interactive interface for changing directories.
def __fzf_cd --env --wrapped [...rest: string] {
    with-env {
        FZF_DEFAULT_OPTS: ($env.FZF_DEFAULT_OPTS | default $__fzf_defaults)
    } {
        if "FZF_ALT_C_COMMAND" in $env {
            let command = $env.FZF_ALT_C_COMMAND | split row " "
            run-external ($command | get 0) ...($command | slice 1..) | fzf ...$env.FZF_DEFAULT_OPTS ...$rest
        } else {
            fzf ...$rest --walker=dir,hidden,follow ...$env.FZF_DEFAULT_OPTS
        }
    }
}

$env.config.keybindings = $env.config.keybindings | append [
    {
        name: fzf_select
        modifier: control
        keycode: char_t
        mode: [emacs vi_normal vi_insert]
        event: {
            send: ExecuteHostCommand
            cmd: "commandline edit --insert (
                __fzf_select '--multi'
                | lines
                | str join ' '
            )"
        }
    }

    {
        name: fzf_parent_select
        modifier: alt
        keycode: char_t
        mode: [emacs vi_normal vi_insert]
        event: {
            send: ExecuteHostCommand
            cmd: "commandline edit --insert (
                __fzf_select '--multi' '--walker-root=../'
                | lines
                | str join ' '
            )"
        }
    }

    {
        name: fzf_cd
        modifier: alt
        keycode: char_c
        mode: [emacs vi_normal vi_insert]
        event: {
            send: ExecuteHostCommand
            cmd: "dirs add (__fzf_cd)"
        }
    }

    {
        name: fzf_alt_cd
        modifier: alt_shift
        keycode: char_c
        mode: [emacs vi_normal vi_insert]
        event: {
            send: ExecuteHostCommand
            cmd: r#'dirs add (FZF_ALT_C_COMMAND=$"($env.FZF_ALT_SHIFT_C_COMMAND? | default null | str join ' ')" __fzf_cd)'#
        }
    }

    {
        name: fzf_cd_into_typical_projects_dir
        modifier: alt
        keycode: char_p
        mode: [emacs vi_normal vi_insert]
        event: {
            send: ExecuteHostCommand
            cmd: r#'dirs add (__fzf_select --walker-root $env.XDG_PROJECTS_DIR $env.XDG_DOCUMENTS_DIR --walker dir,hidden)'#
        }
    }
]

$env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge deep --strategy=append {
    FZF_CTRL_T_COMMAND: $envconvert_cmdstring
    FZF_ALT_C_COMMAND: $envconvert_cmdstring
    FZF_ALT_SHIFT_C_COMMAND: $envconvert_cmdstring
    FZF_DEFAULT_OPTS: $envconvert_cmdstring
    FZF_DEFAULT_COMMAND: $envconvert_cmdstring
}
