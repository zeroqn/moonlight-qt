# Moonlight Qt prebuilt Nix flake

This flake pins Moonlight Qt commit `1d1fe1aac39dd414ed825fe834b84a0e4eea8338`.
CI builds it once and publishes `moonlight-qt-main-x86_64-linux.tar.gz` on the rolling `main-build` GitHub release. Downstream systems install that prebuilt package by default.

## Downstream NixOS usage

```nix
{
  inputs.moonlight-qt.url = "github:zeroqn/moonlight-qt";

  outputs = { nixpkgs, moonlight-qt, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        moonlight-qt.nixosModules.default
        ({ pkgs, ... }: {
          environment.systemPackages = [ pkgs.moonlight-qt ];
        })
      ];
    };
  };
}
```

Without the overlay:

```nix
environment.systemPackages = [
  moonlight-qt.packages.${pkgs.system}.default
];
```

The source build used to create release assets is available as `packages.x86_64-linux.releaseBuild`.

After the `main-build` release asset has been published, update its pinned URL and hash:

```console
nix run .#update-release-assets
```
