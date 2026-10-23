{
  outputs = {...}: {
    flake = inputs: {
      systems,
      # System-agnostic
      overlays ? null,
      nixosModules ? null,
      nixosConfigurations ? null,
      templates ? null,
      # System-specific
      formatter ? null,
      checks ? null,
      packages ? null,
      apps ? null,
      devShells ? null,
    }: let
      nixpkgs =
        if inputs ? nixpkgs
        then inputs.nixpkgs
        else builtins.throw "expected inputs to contain `nixpgs`";

      nixlibs = import ./lib {inherit inputs systems nixpkgs;};
      libsys = nixlibs.libsys;

      optionalConfig = configClosure:
        nixpkgs.lib.optionalAttrs
        (configClosure != null)
        (libsys.forEachConfig configClosure);

      optionalModule = modules:
        nixpkgs.lib.optionalAttrs
        (modules != null)
        (libsys.forEachModule modules);

      optionalSystem = systemClosure:
        nixpkgs.lib.optionalAttrs
        (systemClosure != null)
        (libsys.forEachSystem systemClosure);
    in {
      # No system

      overlays = optionalConfig overlays;

      nixosModules = optionalModule nixosModules;

      nixosConfigurations = optionalConfig nixosConfigurations;

      templates = optionalConfig templates;

      # Per-system

      formatter = optionalSystem formatter;

      checks = optionalSystem checks;

      packages = optionalSystem packages;

      apps = optionalSystem apps;

      devShells = optionalSystem devShells;
    };
  };
}
