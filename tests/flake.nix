{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixlib.url = "path:../.";

    external.url = "path:./external/";
    external.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixlib, ...} @ inputs:
    nixlib.flake inputs ({
      self,
      libsys,
      ...
    }: {
      systems = ["x86_64-linux"];

      overlays = {
        bazz = final: prev: {
          final.foo = prev.hello;
        };
      };

      nixosModules = {
        bazz = {lib, ...}: {
          options.bazz = {
            foo = lib.mkOption {
              description = "An example option";
              type = lib.types.str;
              default = "foo";
            };
          };
        };
      };

      nixosConfigurations = {
        bazz = libsys.nixosSystem {
          imports = [self.nixosModules.bazz];

          system.stateVersion = "26.11";
        };
      };

      perSystem = {
        self',
        external',
        pkgs,
        lib,
        libpkgs,
        libmodules,
        ...
      }: {
        formatter = pkgs.alejandra;

        checks = {
          fmt-check = pkgs.writeShellApplication {
            name = "fmt-check";
            text = "${lib.getExe self'.formatter} -c .";
          };
        };

        packages = {
          env = libpkgs.mkEnv {
            packages = lib.attrValues external'.packages;
          };

          docs = libmodules.docs {
            modules = [self'.nixosModules.bazz];
            name = "bazz";
          };
        };

        apps = {
          env = libpkgs.mkApp {
            package = self'.packages.env;
          };
        };

        devShells = {
          default = pkgs.mkShell {
            packages = [self'.packages.env];
          };
        };
      };
    });
}
