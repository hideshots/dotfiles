{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-yazi-plugins = {
      url = "github:lordkekz/nix-yazi-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, home-manager, ... }@inputs:
  let
    system          = "x86_64-linux";
    lib             = nixpkgs.lib;
    pkgs            = import nixpkgs {
      system = system;
      config.allowUnfree = true;
      nixpkgs.overlays = [
        (final: prev: {
          nvchad = inputs.nvchad4nix.packages."${pkgs.system}".nvchad;
        })
      ];
    };
    specialArgs     = { inherit system inputs; };
    extraSpecialArgs = { inherit system inputs; };
  in {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./configuration.nix
          ({ config, pkgs, ... }: {
            networking.hostName = "nixos";
            nixpkgs.hostPlatform = system;
          })
          nixos-wsl.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nixos = import ./home.nix;
            home-manager.extraSpecialArgs = extraSpecialArgs;
          }
        ];
      };
    };
  };
}
