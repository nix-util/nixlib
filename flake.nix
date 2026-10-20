{
  outputs = {...}: {
    util = {
      inputs,
      systems,
    }: let
      nixpkgs =
        if inputs ? nixpkgs
        then inputs.nixpkgs
        else builtins.throw "expected inputs to contain `nixpgs`";
    in rec {
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

          libs = import ./lib {inherit nixpkgs pkgs lib;};

          inputSystems = mapInputSystems {inherit inputs system;};
        in
          {inherit system pkgs lib;} // libs // inputSystems)
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
          acc: _input_key: outputs:
            acc // builtins.removeAttrs outputs.nixosModules ["default"]
        )
        {}
        has_modules;

      mapModules = modules:
        nixpkgs.lib.mapAttrs
        (name: module: {
          pkgs,
          lib,
          ...
        }: let
          system = pkgs.stdenv.hostPlatform.system;
          libs = import ./lib {inherit nixpkgs pkgs lib;};
          inputSystems = mapInputSystems {inherit inputs system;};
        in {
          imports = [
            ({config, ...}: {config._module.args = libs // {inputs = inputSystems;};})
            module
          ];
        })
        modules;

      forEachModule = mapAttrs:
        mapModules (mapAttrs {}) // mapInputModules inputs;
    };
  };
}
