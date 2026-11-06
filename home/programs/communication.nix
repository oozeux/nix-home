{ pkgs, ... }:

{
  home.packages = with pkgs; [
    discord
    #discord-ptb
    #discord-canary
    #telegram-desktop
    #vesktop

    #Installer
  ];
}
