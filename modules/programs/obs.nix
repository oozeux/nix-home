{ config, pkgs, ... }:

{
  # ─────────────────────────────────────────────
  # Communication
  # ─────────────────────────────────────────────

  programs.obs-studio = {
    enable = true;

    # Cuda Support
    package = pkgs.obs-studio.override {
      cudaSupport = true;
    };

    # Instalar plugins
    # plugins = with pkgs.obs-studio-plugins; [
    #   obs-multi-rtmp
    #   obs-vertical-canvas
    # ];
  };
}