{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # App store 
    #bazaar
   
    # Bars / launchers / session controls
    #waybar
    #rofi
    #wlogout

    # Office Utilities
    libreoffice
    xournalpp
    solaar

    # Desktop utilities
    wlsunset
    libnotify
    networkmanagerapplet
    unrar
    
    #Installer
  ];
}
