{
  nixpkgs,
  pkgs,
  lib,
  ...
}: {
  libpkgs = import ./pkgs.nix {inherit pkgs lib;};
  libmodules = import ./modules.nix {inherit nixpkgs pkgs lib;};
}
