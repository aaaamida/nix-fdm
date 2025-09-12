{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./fdm.nix {}
