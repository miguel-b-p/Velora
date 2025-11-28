# No seu configuration.nix
{
  inputs = {
    velora.url = "path:/home/mingas/projetos/Velora";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    {
      self,
      velora,
      nixpkgs,
      ...
    }:
    {
      nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          velora.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
