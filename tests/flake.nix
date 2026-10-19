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

    nixosModules = util.forEachModule ({...}: {
      bazz = {
        pkgs,
        lib,
        ...
      }: {
        options.bazz = lib.mkOption {
          description = "An example module";
          type = lib.types.submodule {
            options = {
              val = lib.mkOption {
                description = "A simple test value";
                type = lib.types.str;
              };
            };
          };
        };
      };
    });

    packages = util.forEachSystem ({
      self,
      external,
      libpkgs,
      libattrs,
      libmodules,
      ...
    }: {
      env = libpkgs.mkEnv {
        packages = libattrs.attrsToValueList external.packages;
      };

      docs = libmodules.docs {
        module = self.nixosModules.bazz;
        name = "bazz";
      };
    });

    apps = util.forEachSystem ({
      external,
      libpkgs,
      ...
    }: {
      default = libpkgs.mkApp {
        package = external.packages.default;
      };
    });

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
