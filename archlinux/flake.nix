{
  inputs = {
    nixpkgs.url       = "github:NixOS/nixpkgs/nixos-unstable";
    apple-fonts.url   = "github:Lyndeno/apple-fonts.nix";
    appleEmoji.url    = "github:samuelngs/apple-emoji-linux";

    minimal-tmux = {
      url = "github:niksingh710/minimal-tmux-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, ... }@inputs:
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
        stylix.homeModules.stylix
      ];
    };
  };
}
