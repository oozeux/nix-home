
{ config, pkgs, inputs, ... }:

{
  # ============================================================================
  # HYPRLAND & HYPR ECOSYSTEM
  # ============================================================================

  programs.hyprland = {
    enable = true;
    # withUWSM = true;

    xwayland.enable = true;

    package =
      inputs.hyprnix.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    portalPackage =
      inputs.hyprnix.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # HYPRLAND ECOSYSTEM
    hyprpicker
    hyprsunset
    hyprshutdown
    hyprsysteminfo
    hypridle
  ];

  # ============================================================================
  # CACHIX HYPRLAND
  # ============================================================================

  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
    ];

    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
