{
  description = "Godot Engine – Multi-platform 2D and 3D game engine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
#          godot = pkgs.godot_4.overrideAttrs (old: rec {
          godot = pkgs.godot_4.overrideAttrs rec {
            version = "4.3.0-rc";
            commitHash = "3e0c10d3931afb62a30f26532a9f7709ee68bf2c";

            src = pkgs.fetchFromGitHub {
              owner = "godotengine";
              repo = "godot";
              rev = commitHash;
              sha256 = "sha256-/MC5cCIVXclm4YoeDA6in0v/XJFMGUHvVA+lkD/1MUY=";
#              sha256 = pkgs.lib.fakeSha256;
            };
            outputs = [ "out" ];
            installPhase = ''
              mkdir -p "$out/bin"
              cp bin/godot.* $out/bin/
            '';
          };
          godot_template_debug = godot.override {withTarget="template_debug";};
          godot_template_release = godot.override {withTarget="template_release";};
          godot_editor = godot.override {withTarget="editor";};
         in { 
          packages = rec {
            template_release = godot_template_release;
            template_debug = godot_template_debug;
            editor = godot_editor;
            default = editor;
          };
          devShells.default = config.packages.default;
        };
      flake = {
      };
    };
}
