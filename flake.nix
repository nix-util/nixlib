{
  outputs = _: {
    flake = inputs: flakeLambda: let
      nixpkgs =
        if inputs ? nixpkgs
        then inputs.nixpkgs
        else builtins.throw "expected inputs to contain `nixpkgs`";

      nixlibs = import ./lib {inherit inputs;};
      lib = nixpkgs.lib;
      libsys = nixlibs.libsys;

      flakeAttrs = libsys.forEachAgnostic flakeLambda;

      systems =
        if flakeAttrs ? systems
        then flakeAttrs.systems
        else builtins.throw "expected flake outputs to contain `systems";

      flakeSystems =
        if flakeAttrs? perSystem
        then
          builtins.map (system: let
            withSystem = nixlibs.withSystem {inherit system;};
            rawSystem = withSystem.libpkgs.forEachSystem flakeAttrs.perSystem;
            fullSystem = builtins.mapAttrs (_name: value: {${system} = value;}) rawSystem;
          in
            fullSystem)
          systems
        else [];

      systemAttrs = lib.mergeAttrsList flakeSystems;
    in
      lib.optionalAttrs (flakeAttrs ? overlays) {inherit (flakeAttrs) overlays;}
      // lib.optionalAttrs (flakeAttrs ? nixosModules) {inherit (flakeAttrs) nixosModules;}
      // lib.optionalAttrs (flakeAttrs ? nixosConfigurations) {inherit (flakeAttrs) nixosConfigurations;}
      // lib.optionalAttrs (systemAttrs ? formatter) {inherit (systemAttrs) formatter;};
  };
}
