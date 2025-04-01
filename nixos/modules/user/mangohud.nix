{ config, pkgs, ... }:

{
  programs.mangohud = {
    enable = true;
    settings = {
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      cpu_stats = true;
      cpu_temp = true;
      vram = true;
      fps = true;
      frametime = true;
      fps_metrics = "0.01";
      throttling_status = true;
      gamemode = true;
      # font_size = 24;
      text_outline = true;
      text_outline_thickness = 0.0;
      # background_alpha = -1;
      alpha = 1.0;
      toggle_hud = "Shift_R+F12";
      reset_fps_metrics = "Shift_R+f9";
    };
  };
}
