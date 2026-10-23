{
  inputs,
  nixpkgs,
  pkgs,
  lib,
  ...
}: {
  libpkgs = import ./pkgs.nix {inherit pkgs lib;};
  libmodules = import ./modules.nix {inherit inputs nixpkgs pkgs lib;};
}
