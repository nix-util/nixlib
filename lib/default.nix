inputs: {
  libsys = import ./sys.nix inputs;

  withPkgs = {pkgs, ...}: let
    lib = pkgs.lib;
    nixlib = builtins.removeAttrs (import ./. inputs) ["withPkgs"];
    pkgsInputs = {inherit pkgs lib nixlib;} // inputs;
  in
    {
      libpkgs = import ./pkgs.nix pkgsInputs;
      libmodules = import ./modules.nix pkgsInputs;
    }
    // nixlib;
}
