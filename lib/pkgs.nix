{
  inputs,
  system,
  nixlib,
  ...
} @ args: let
  nixpkgs =
    if inputs ? nixpkgs
    then inputs.nixpkgs
    else builtins.throw "expected inputs to contain `nixpgs`";

  pkgs = nixpkgs.legacyPackages.${system};
  lib = pkgs.lib;
in {
  forEachSystem = systemLambda: let
    inputSystem = nixlib.libsys.mapFlakeSystemInputs system;
    self' = builtins.mapAttrs (nixlib.libsys.mapFlakeSystemOutput system) inputs.self;

    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    withSystem = nixlib.withSystem args;

    pkgsInputs = {inherit self' pkgs lib;} // withSystem // inputSystem;
  in
    systemLambda pkgsInputs;

  mkApp = {package, ...}:
    {
      type = "app";
      program = lib.getExe package;
    }
    // lib.optionalAttrs (package ? meta) package.meta;

  mkEnv = {packages, ...}:
    pkgs.buildEnv {
      name = "env";
      paths = packages;
    };

  mkOverride = overrideAttrs: lib.makeOverridable overrideAttrs {};
}
