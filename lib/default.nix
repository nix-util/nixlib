inputs: {
  libsys = import ./sys.nix inputs;

  withSystem = {system, ...}: let
    nixlib = builtins.removeAttrs (import ./. inputs) ["withSystem"];
    pkgsInputs = {inherit system nixlib;} // inputs;
  in
    {
      libpkgs = import ./pkgs.nix pkgsInputs;
      libmodules = import ./modules.nix pkgsInputs;
    }
    // nixlib;
}
