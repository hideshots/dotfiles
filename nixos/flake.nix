{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    stylix.url = "github:danth/stylix";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    nix-gaming.url = "github:fufexan/nix-gaming";
    iio-hyprland.url = "github:JeanSchoeller/iio-hyprland";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-yazi-plugins = {
      url = "github:lordkekz/nix-yazi-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, nix-gaming, ... }@inputs:
  let
    system          = "x86_64-linux";
    lib             = nixpkgs.lib;
    specialArgs     = { inherit system inputs; };
    extraSpecialArgs = { inherit system inputs; };
  in {
    nixosConfigurations = {
      dev = lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/dev/configuration.nix
          stylix.nixosModules.stylix
          ({ config, pkgs, ... }: {
            networking.hostName = "dev";
            nixpkgs.hostPlatform = system;
          })
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.dev = import ./hosts/dev/home.nix;
            home-manager.extraSpecialArgs = extraSpecialArgs;
          }
        ];
      };

      lenovo = lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/lenovo/configuration.nix
          stylix.nixosModules.stylix
          ({ config, pkgs, ... }: {
            networking.hostName = "lenovo";
            nixpkgs.hostPlatform = system;
          })
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.lenovo = import ./hosts/lenovo/home.nix;
            home-manager.extraSpecialArgs = extraSpecialArgs;
          }
        ];
      };

      drama = lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/drama/configuration.nix
          stylix.nixosModules.stylix
          ({ config, pkgs, ... }: {
            networking.hostName = "drama";
            nixpkgs.hostPlatform = system;
          })
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.drama = import ./hosts/drama/home.nix;
            home-manager.extraSpecialArgs = extraSpecialArgs;
          }
        ];
      };
    };
  };
}
