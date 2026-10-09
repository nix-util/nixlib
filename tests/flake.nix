{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixlib.url = "path:../.";

    external.url = "path:./external/";
    external.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixlib, ...} @ inputs: let
    systems = ["x86_64-linux"];
    util = nixlib.util {inherit inputs systems;};
  in {
    formatter = util.forEachSystem ({pkgs, ...}: pkgs.alejandra);

    packages = util.forEachSystem ({external, ...}: external.packages);

    devShells = util.forEachSystem ({
      self,
      pkgs,
      lib,
      ...
    }: {
      default = let
        packages =
          builtins.map
          (attr: attr.value)
          (lib.attrsToList self.packages);
      in
        pkgs.mkShell {
          inherit packages;
        };
    });
  };
}
