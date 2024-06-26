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
          godot = pkgs.godot_4.overrideAttrs (p: f: rec {
            version = "4.3.0beta2";
            commitHash = "95110ddcb41ba4b9b1f8c9bf58c8910f6616e60a";

            src = pkgs.fetchFromGitHub {
              owner = "godotengine";
              repo = "godot";
              rev = commitHash;
              sha256 = "sha256-j8xQI4vRkTtohkva5+C8dXVg+/cIAPOe1IsVJdW6THY="; #pkgs.lib.fakeSha256;
            };
          });
         in { 
          packages = rec {
            release = pkgs.callPackage godot { withTarget = "template_release"; };
            debug = pkgs.callPackage godot { withTarget = "template_debug"; };
            editor = pkgs.callPackage godot { withTarget = "editor"; };
            default = editor;
          };
          devShells.default = config.packages.editor;
        };
      flake = {
      };
    };
}
