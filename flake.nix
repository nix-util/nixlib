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
      mapInputs = {
        inputs,
        system,
        lib,
      }:
        lib.mapAttrs (
          _input_key: outputs:
            lib.mapAttrs (
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
        in
          {
            inherit system pkgs lib;
          }
          // mapInputs {
            inherit inputs system lib;
          })
        systems;

      forEachSystem = mapAttrs:
        nixpkgs.lib.genAttrs'
        (mapSystems systems)
        (inputs: nixpkgs.lib.nameValuePair inputs.system (mapAttrs inputs));
    };
  };
}
