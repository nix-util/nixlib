{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixlib.url = "github:nix-util/nixlib";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixlib, ...} @ inputs:
    nixlib.flake inputs ({
      self,
      nixpkgs,
      rust-overlay,
      lib,
      ...
    }: {
      systems = ["x86_64-linux"];

      overlays = {inherit (rust-overlay.overlays) rust-overlay;};

      pkgsOverlays = lib.attrValues self.overlays;

      perSystem = {
        self',
        pkgs,
        lib,
        libpkgs,
        ...
      }: {
        devShells = {
          default = with pkgs;
            mkShell {
              packages = [
                (rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)
              ];
            };
        };
      };
    });
}
