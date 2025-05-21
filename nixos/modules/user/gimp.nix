{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    gimp3-with-plugins

    # gimp3Plugins.waveletSharpen
    # gimp3Plugins.exposureBlend
    # gimp3Plugins.gimplensfun
    # gimp3Plugins.texturize
    # gimp3Plugins.lqrPlugin
    # gimp3Plugins.lightning
    # gimp3Plugins.farbfeld
    # gimp3Plugins.fourier
    # gimp3Plugins.gmic
    # gimp3Plugins.bimp
  ];
}
