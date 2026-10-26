{
  inputs,
  system,
  ...
} @ args: let
  nixpkgs =
    if inputs ? nixpkgs
    then inputs.nixpkgs
    else builtins.throw "expected inputs to contain `nixpgs`";

  pkgs = nixpkgs.legacyPackages.${system};
  lib = pkgs.lib;

  mapFlakeSystemOutput = _output_name: output:
    if output ? ${system}
    then output.${system}
    else output;

  mapFlakeSystemInputs = inputs: let
    # WARN: `self` cannot be mapped directly as it is itself a recursive attrset
    # of the current flake's own outputs, therefore indexing `self.outputs`
    # leads to an infinite recursion error.
    safeInputs = builtins.removeAttrs inputs ["self"];
  in
    lib.mapAttrs'
    (
      input_name: flake_input: let
        hasSystem = builtins.any (output: output ? ${system}) (lib.attrValues flake_input.outputs);
        withSystem = builtins.mapAttrs mapFlakeSystemOutput;
      in
        if hasSystem == true
        then lib.nameValuePair "${input_name}'" withSystem
        else lib.nameValuePair input_name withSystem
    )
    safeInputs;
in {
  forEachSystem = systemLambda: let
    inputSystem = mapFlakeSystemInputs inputs;
    self' = mapFlakeSystemOutput "self" inputs.self;

    nixlib = import ./. args;
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
