{
  pkgs,
  lib,
  ...
}: {
  mkApp = {package}:
    {
      type = "app";
      program = lib.getExe package;
    }
    // lib.optionalAttrs (package ? meta) package.meta;

  mkEnv = {packages}:
    pkgs.buildEnv {
      name = "env";
      paths = packages;
    };
}
