{ pkgs, ... }:

{
  home.packages = with pkgs; [
  # Game performance and monitoring
  mangohud
  goverlay

  # TwintailLauncher Gachagames launcher
  #inputs.twintaillauncher.packages.${pkgs.stdenv.hostPlatform.system}.default


  # Game launchers
  heroic
  lutris
  
  #Installer
  ];
}
