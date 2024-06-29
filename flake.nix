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
            version = "4.3.0beta2";
            commitHash = "25de53e147a04ba15afc461b3ad4aa1884ff927d";

            src = pkgs.fetchFromGitHub {
              owner = "godotengine";
              repo = "godot";
              rev = commitHash;
              sha256 = "sha256-wQeOcvqJ8AWrM40WtM40QJEtzD7MYnm4OKiG4+c0fd0=";
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
