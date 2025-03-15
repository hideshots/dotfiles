{ pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in {
  programs.spicetify = {
    enable = true;
    # theme = spicePkgs.themes.defaultDynamic;
    # theme = spicePkgs.themes.text;
    theme = spicePkgs.themes.default;
    colorScheme = "default";

    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      keyboardShortcut
      playlistIcons
      betterGenres
      hidePodcasts
      shuffle
    ];

    enabledCustomApps = with spicePkgs.apps; [
      lyricsPlus
      newReleases
      nameThatTune
    ];
  };
}
