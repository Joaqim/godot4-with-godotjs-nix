{
  description = "Godot Engine with GodotJS and V8 dependencies";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [];
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        # GodotJS module with v8 dependencies
        godotjs = let
          GodotJS_src = pkgs.fetchFromGitHub rec {
            owner = "ialex32x";
            repo = "GodotJS";
            name = repo;
            rev = "main";
            sha256 = "sha256-+82vBIrLrrmSzVQpo1MJHuvAi2QVycZKY4h4vFX5Fsk=";
          };

          v8zip = pkgs.fetchurl {
            name = "v8.zip";
            url = "https://github.com/ialex32x/GodotJS-Dependencies/releases/download/v8_r6/v8_r6.zip";
            sha256 = "sha256-BGGS1w/r3DBlg7uNWruGoehzJDUu7O8YmM7u38s70Ac=";
          };
        in
          pkgs.stdenv.mkDerivation {
            name = "GodotJS";

            srcs = [
              GodotJS_src
              v8zip
            ];
            buildInputs = [pkgs.unzip];

            unpackPhase = ''
              cp -r ${GodotJS_src}/* .
              unzip ${v8zip} -d .
            '';

            installPhase = ''
              mkdir -p "$out"
              cp -r ./* $out/
            '';
          };

        # Override the default Godot package to add GodotJS module
        godot = let
          commitHash = "3504c98c1233bbd2506e89ce46509bc79afaec17";

          godot_src = pkgs.fetchFromGitHub rec {
            owner = "godotengine";
            repo = "godot";
            name = repo;
            rev = commitHash;
            sha256 = "sha256-w+tmFBhN1uPNK++oHeN4GA+r9p9vsYz8td+4rf2E5sE=";
          };
        in
          pkgs.godot_4.overrideAttrs (old: {
            inherit commitHash;
            version = "4.2.0";

            srcs = [
              godot_src
              godotjs
            ];

            sourceRoot = "godot";
            nativeBuildInputs = old.nativeBuildInputs ++ [pkgs.mold];

            preBuild = ''
              mkdir -p ./modules/GodotJS
              cp -r ../GodotJS/* ./modules/GodotJS/
              chmod -R 755 ./modules/GodotJS
            '';

            buildPhase = ''
              runHook preBuild
              scons platform=linuxbsd dev_build=yes
              runHook postBuild
            '';

            outputs = ["out"];
            installPhase = ''
              mkdir -p "$out/bin"
              cp bin/godot.* $out/bin/
            '';
          });

        # Define different build targets (template release, template debug, editor)
        godot_template_debug = godot.override {withTarget = "template_debug";};
        godot_template_release = godot.override {withTarget = "template_release";};
        godot_editor = godot.override {withTarget = "editor";};
      in {
        # Expose packages to the system
        packages = rec {
          template_release = godot_template_release;
          template_debug = godot_template_debug;
          editor = godot_editor;
          default = editor;
        };

        # Define the default dev shell
        devShells.default = config.packages.default;
      };
      flake = {
      };
    };
}
