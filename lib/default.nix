{
  pkgs,
  lib,
  ...
}: {
  libpkgs = import ./pkgs.nix {inherit pkgs lib;};
  libattrs = import ./attrs.nix {inherit pkgs lib;};
  libmodules = import ./modules.nix {inherit pkgs lib;};
}
