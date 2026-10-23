{
  inputs,
  systems,
  nixpkgs,
  ...
}: rec {
  mapInputSystems = {
    inputs,
    system,
  }:
    builtins.mapAttrs (
      _input_key: outputs:
        builtins.mapAttrs (
          output_key: maybe_system:
            if maybe_system ? ${system}
            then maybe_system.${system}
            else maybe_system
        )
        outputs
    )
    inputs;

  mapSystems = systems:
    map
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      nixlib = import ./. {inherit inputs systems nixpkgs;};
      nixlibWithPkgs = nixlib.withPkgs {inherit pkgs;};

      inputSystems = mapInputSystems {inherit inputs system;};
    in
      {inherit system pkgs lib;} // nixlibWithPkgs // inputSystems)
    systems;

  forEachSystem = mapAttrs:
    nixpkgs.lib.genAttrs'
    (mapSystems systems)
    (inputs: nixpkgs.lib.nameValuePair inputs.system (mapAttrs inputs));

  mapInputModules = inputs: let
    safe_inputs = builtins.removeAttrs inputs ["self" "nixpkgs"];
    has_modules = nixpkgs.lib.filterAttrs (_input_key: outputs: outputs ? nixosModules) safe_inputs;
  in
    nixpkgs.lib.foldlAttrs (
      acc: input_key: outputs:
        acc // builtins.removeAttrs outputs.nixosModules ["default"]
    )
    {}
    has_modules;

  forEachModule = modules:
    modules // mapInputModules inputs;

  forEachConfig = mapAttrs: let
    nixlib = import ./. {inherit inputs systems nixpkgs;};
    libsys = nixlib.libsys;
    combinedInputs = {inherit libsys;} // inputs;
  in
    mapAttrs combinedInputs;

  nixosSystem = {
    imports,
    specialArgs,
    ...
  } @ inputs: let
    module = builtins.removeAttrs inputs ["imports" "specialArgs"];
    nixLibInject = {pkgs, ...}: let
      nixlib = import ./. {inherit inputs systems nixpkgs;};
      nixlibWithPkgs = nixlib.withPkgs {inherit pkgs;};
    in {
      config._module.args = nixlibWithPkgs;
    };
  in
    nixpkgs.lib.nixosSystem {
      modules = [module nixLibInject] + imports;
      specialArgs = specialArgs;
    };
}
