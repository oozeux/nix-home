{ pkgs, inputs, ... }:

{
  # ─────────────────────────────────────────────
  # Linux Packages
  # ─────────────────────────────────────────────
  
  # GameMode root-level
  programs.gamemode.enable = true;

  # ─────────────────────────────────────────────
  # Storage
  # ─────────────────────────────────────────────

  # Mount disks
  services.udisks2.enable = true;

  # papelera, montaje, redes
  services.gvfs.enable = true;

  # ─────────────────────────────────────────────
  # Printing & Fonts
  # ─────────────────────────────────────────────

  services.printing.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono      # íconos (obligatoria)
    nerd-fonts.symbols-only        # respaldo de glifos
    nunito
    nunito-sans
    mplus-outline-fonts.osdnRelease
    mplus-outline-fonts.githubRelease
    migu                           # opcional, japonés
    (google-fonts.override {
      fonts = [ "Silkscreen" "DotGothic16" "VT323" ];
    })
  ];
}