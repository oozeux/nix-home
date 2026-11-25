{ config, pkgs, inputs, ... }:

{
  imports = [
    # ───────────────────────────────────────────
    # Hardware
    # ───────────────────────────────────────────

    ./hardware-configuration.nix

    # ───────────────────────────────────────────
    # Sistema
    # ───────────────────────────────────────────

    ./modules/audio.nix
    ./modules/boot.nix
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/files.nix
    ./modules/glaunchers.nix
    ./modules/hyprland.nix
    ./modules/linuxpkgs.nix
    ./modules/maintenance.nix
    #./modules/mango.nix
    ./modules/networking.nix
    #./modules/niri.nix
    ./modules/oozelogin.nix
    ./modules/polkit.nix
    ./modules/qemu.nix
    ./modules/quickshell.nix
    ./modules/users.nix
    
    ./modules/nvidia.nix 
    #./modules/amdgpu.nix  

    # ───────────────────────────────────────────

    ./modules/programs/obs.nix
    ./modules/programs/steam.nix
    ./modules/programs/suwayomi.nix

    # ───────────────────────────────────────────
    # Servicios
    # ───────────────────────────────────────────

    ./modules/services/flatpak.nix
    ./modules/services/systemservices.nix

  ];

  # ─────────────────────────────────────────────
  # Home Manager
  # ─────────────────────────────────────────────

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit inputs; };

    users.oozenix = import ./home;
  };

  # ─────────────────────────────────────────────
  # Nix & System Configuration
  # ─────────────────────────────────────────────

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Habilita paquetes propietarios en todo el sistema
  nixpkgs.config.allowUnfree = true;

  # Versión inicial de NixOS
  system.stateVersion = "26.05";
}
