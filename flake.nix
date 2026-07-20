{
  description = "WASM4 template";

  inputs = {
    zig2nix.url = "github:Cloudef/zig2nix";
    wasm4-nix.url = "github:rutrum/wasm4-nix";
  };

  outputs = {
    zig2nix,
    wasm4-nix,
    ...
  }: let
    flake-utils = zig2nix.inputs.flake-utils;
  in (flake-utils.lib.eachDefaultSystem (system: let
    env = zig2nix.outputs.zig-env.${system} {};
  in
    with builtins;
    with env.pkgs.lib; rec {
      packages.foreign = env.package {
        src = cleanSource ./.;
        nativeBuildInputs = [];
        buildInputs = [];
        zigPreferMusl = true;
      };

      packages.default = packages.foreign.override (attrs: {
        zigPreferMusl = false;
        zigWrapperBins = [];
        zigWrapperLibs = attrs.buildInputs or [];
      });

      apps.bundle = {
        type = "app";
        program = "${packages.foreign}/bin/default";
      };
      apps.default = env.app [] "zig build run -- \"$@\"";
      apps.build = env.app [] "zig build \"$@\"";
      apps.watch = env.app [] "zig build -- \"$@\" && w4 watch";
      apps.zig2nix = env.app [] "zig2nix \"$@\"";

      devShells.default = env.mkShell {
        nativeBuildInputs =
          [wasm4-nix.packages.${system}.w4]
          ++ packages.default.nativeBuildInputs
          ++ packages.default.buildInputs
          ++ packages.default.zigWrapperBins
          ++ packages.default.zigWrapperLibs;
      };
    }));
}
