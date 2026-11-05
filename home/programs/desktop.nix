{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # App store 
    bazaar
   
    # Bars / launchers / session controls
    #waybar
    #rofi
    #wlogout

    # Office Utilities
    libreoffice
    xournalpp

    # Desktop utilities
    #wlsunset  #Uncomment if you use niri or mango.
    libnotify
    networkmanagerapplet
    unrar

    #Installer
  ];
}
