# SPDX-FileCopyrightText: 2022-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  packages = [
    python3
    stow

    # Language servers for...
    lua-language-server # ...Lua.
    pyright # ...Python.
    nixd # ...Nix.

    # Formatters for...
    treefmt # ...everything under the sun.
    stylua # ...Lua.
    nixpkgs-fmt # ...Nix.
    black # ...Python.
    nufmt # ... Nushell.
  ];
}
