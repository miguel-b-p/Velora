{
  description = "Velora - Performance optimization modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosModules = {
        velora = import ./modules/default.nix;
        default = self.nixosModules.velora;
      };
    };
}
