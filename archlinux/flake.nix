{
  inputs = {
    nixpkgs.url       = "github:NixOS/nixpkgs/nixos-unstable";
    apple-fonts.url   = "github:Lyndeno/apple-fonts.nix";
    appleEmoji.url    = "github:samuelngs/apple-emoji-linux";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit system inputs; };
  in {
    homeConfigurations.drama = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = extraSpecialArgs;
      modules = [
        ./home.nix
      ];
    };
  };
}
