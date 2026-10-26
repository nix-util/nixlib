{inputs, ...}: let
  nixpkgs =
    if inputs ? nixpkgs
    then inputs.nixpkgs
    else builtins.throw "expected inputs to contain `nixpgs`";
in {
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
