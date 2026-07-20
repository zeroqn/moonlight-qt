{
  description = "Moonlight Qt prebuilt release flake with source-build fallback";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      releaseMeta = builtins.fromJSON (builtins.readFile ./release-assets.json);
      supportedSystems = builtins.attrNames releaseMeta.assets;

      mkSourceBuild = pkgs:
        pkgs.moonlight-qt.overrideAttrs {
          version = "1d1fe1a";
          src = pkgs.fetchFromGitHub {
            owner = "moonlight-stream";
            repo = "moonlight-qt";
            rev = "1d1fe1aac39dd414ed825fe834b84a0e4eea8338";
            hash = "sha256-0cWR9uLQIa1eQOuQMTxbzWg7lFmqQ1hgle/Z+vCC/9k=";
            fetchSubmodules = true;
          };
          patches = [ ];
        };

      mkBinaryPackage = pkgs: system:
        pkgs.callPackage ./prebuilt-package.nix {
          releaseAsset = releaseMeta.assets.${system} // {
            inherit system;
            inherit (releaseMeta) owner repo;
            inherit (releaseMeta.release) tag version;
          };
        };

      overlay = final: prev:
        let
          system = prev.stdenv.hostPlatform.system;
          hasBinary = builtins.hasAttr system releaseMeta.assets;
        in
        {
          moonlight-qt-release-build = mkSourceBuild prev;
        }
        // prev.lib.optionalAttrs hasBinary {
          moonlight-qt = mkBinaryPackage prev system;
          moonlight-qt-bin = final.moonlight-qt;
        };
    in
    (flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        updateReleaseAssets = pkgs.writeShellApplication {
          name = "update-release-assets";
          runtimeInputs = [ pkgs.bash pkgs.curl pkgs.jq pkgs.nix ];
          text = ''
            exec bash ${./updater.sh} "$@"
          '';
        };
      in
      {
        packages = {
          default = pkgs.moonlight-qt;
          moonlight-qt = pkgs.moonlight-qt;
          moonlight-qt-bin = pkgs.moonlight-qt-bin;
          releaseBuild = pkgs.moonlight-qt-release-build;
        };

        apps.update-release-assets = {
          type = "app";
          program = "${updateReleaseAssets}/bin/update-release-assets";
        };
      }))
    // {
      overlays.default = overlay;
      nixosModules.default = { ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}
