{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs_24_11.url = "github:nixos/nixpkgs/24.11";
    flake-utils.url = "github:numtide/flake-utils";
    ps-overlay.url = "github:thomashoneyman/purescript-overlay";
    mkSpagoDerivation = {
      url = "github:jeslie0/mkSpagoDerivation";
      inputs = {
        # the later `purescript-overlay` has no `nix/from-yaml.nix` which `mkSpagoDerivation` imports
        ps-overlay.url = "github:thomashoneyman/purescript-overlay/d7ed2f4e30d39ceabe9689eed1b1686d9a11e2ca";
        registry.url = "github:purescript/registry/fe3f499706755bb8a501bf989ed0f592295bb4e3";
        registry-index.url = "github:purescript/registry-index/a349ca528812c89915ccc98cfbd97c9731aa5d0b";
      };
    };
  };

  outputs = { self, nixpkgs, nixpkgs_24_11, flake-utils, ps-overlay, mkSpagoDerivation }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ mkSpagoDerivation.overlays.default
                       ps-overlay.overlays.default
                     ];
        };

        # Build dependencies (required for nix run/build)
        buildDependencies = [
          pkgs.esbuild
          pkgs.purs-backend-es
          pkgs.purs-unstable
          pkgs.spago-unstable
          # pkgs.nodejs
          pkgs.dhall
        ];

        # Development-only dependencies (IDE support, etc.)
        devOnlyDependencies = [
          pkgs.dhall-lsp-server
        ];

        myPackage =
            pkgs.mkSpagoDerivation {
              # given explicitly, so that `mkSpagoDerivation` would not parse `spago.yaml`, its parser fails on it
              pname = "report-web";
              spagoYaml = ./spago.yaml;
              spagoLock = ./spago.lock;
              src = ./.;
              version = "0.1.0";
              nativeBuildInputs = buildDependencies ++ [
                # Additional build-specific dependencies if needed
                # nixpkgs_24_11.libtinfo
                # nixpkgs_24_11.nodePackages.parcel
              ];
              buildPhase = ''
                spago build --json-errors
                spago bundle --module Demo.GamesWebApp --outfile ./web/demo-games-app.js --platform browser --bundle-type app
                spago bundle --module Demo.ReportWebApp --outfile ./web/demo-rep-app.js --platform browser --bundle-type app
              '';
              installPhase = "mkdir $out; cp -r ./web $out";
              buildNodeModulesArgs = {
                npmRoot = ./.;
                nodejs = pkgs.nodejs;
              };
            };

        myApp = {
            type = "app";
            program = "sh ./serve-demo-games-nix.sh";
        };

      in
        {
          packages.default = myPackage;

          apps.default = myApp;

          devShells.default = pkgs.mkShell {
            buildInputs = buildDependencies ++ devOnlyDependencies;
          };
        }

    );
}
