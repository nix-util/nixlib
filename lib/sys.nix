{inputs, ...}: let
  nixpkgs =
    if inputs ? nixpkgs
    then inputs.nixpkgs
    else builtins.throw "expected inputs to contain `nixpgs`";
in rec {
  mapFlakeSystemOutput = system: _output_name: output:
    if output ? ${system}
    then output.${system}
    else output;

  mapFlakeSystemInputs = system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;

    # WARN: `self` cannot be mapped directly as it is itself a recursive attrset
    # of the current flake's own outputs, therefore indexing `self.outputs`
    # leads to an infinite recursion error.
    safeInputs = builtins.removeAttrs inputs ["self"];
  in
    lib.mapAttrs'
    (
      input_name: flake_input: let
        hasSystem = builtins.any (output: output ? ${system}) (lib.attrValues flake_input.outputs);
        withSystem = builtins.mapAttrs (mapFlakeSystemOutput system) flake_input.outputs;
      in
        if hasSystem == true
        then lib.nameValuePair "${input_name}'" withSystem
        else lib.nameValuePair input_name withSystem
    )
    safeInputs;

  forEachAgnostic = mapAttrs: let
    nixlib = import ./. {inherit inputs nixpkgs;};
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
      nixlib = import ./. {inherit inputs nixpkgs;};
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
