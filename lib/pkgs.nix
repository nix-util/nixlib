{
  inputs,
  system,
  nixlib,
  ...
} @ args: let
  nixpkgs =
    if inputs ? nixpkgs
    then inputs.nixpkgs
    else builtins.throw "expected inputs to contain `nixpkgs`";

  pkgs =
    if inputs.self ? pkgsOverlays
    then
      import nixpkgs {
        inherit system;
        overlays = inputs.self.pkgsOverlays;
      }
    else nixpkgs.legacyPackages.${system};

  lib = pkgs.lib;
in {
  forEachSystem = systemLambda: let
    self' = builtins.mapAttrs (nixlib.libsys.mapFlakeSystemOutput system) inputs.self;
    withSystem = nixlib.withSystem args;
    inputSystem = nixlib.libsys.mapFlakeSystemInputs system;

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
