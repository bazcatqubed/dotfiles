# SPDX-FileCopyrightText: 2022-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

{
  description = "Basic flake template for setting up development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let systems = inputs.flake-utils.lib.defaultSystems;
    in inputs.flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShell =
        import ./shell.nix { inherit pkgs; };

      formatter = pkgs.treefmt;
    });
}
