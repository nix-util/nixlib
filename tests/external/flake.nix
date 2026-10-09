{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = rec {
      lolcat = pkgs.lolcat;
      cowsay = pkgs.cowsay;

      default = cowsay;
    };
  };
}
