{ pkgs, ... }:

{
  home.packages = with pkgs; [
  # Game performance and monitoring
  mangohud
  goverlay

  # Game launchers
  heroic
  lutris
  
  #Installer
  ];
}
