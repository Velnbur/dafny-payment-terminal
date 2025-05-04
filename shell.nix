{ pkgs ? import <nixpkgs> {} }:
let
  dotnetSdk = pkgs.dotnetCorePackages.sdk_8_0;
in pkgs.mkShell {
  packages = [
    dotnetSdk
    pkgs.dafny
  ];

  DOTNET_ROOT = "${dotnetSdk}/share/dotnet";
}
