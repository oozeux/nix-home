{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    #loadInNixShell = true;
    #direnvrcExtra = "";
    nix-direnv.enable = true;
  };

  # # Docker Virtualization
  #   virtualisation.docker = {
  #     enable = true;
  #     rootless = {
  #       enable = true;
  #       setSocketVariable = true;
  #     };
  #   };
  #   users.users.oozenix.extraGroups = [ "docker" ];


  # NixPackages
   environment.systemPackages = with pkgs; [
    # Git / Nix
    git
    #gh
    #nixd
    #nixfmt
    nix-search-cli
    #lazygit
    
    # Runtimes
    ruff
    uv
    openssl
    bbe
    mpv-unwrapped
    libsecret
    aria2

    # Metadata Tools
    # c2patool
    # exiftool

    # Java 
    openjdk
    jdk17
    jdk21
    jdk25

    # Python
    python3Packages.pip
    #python314Packages.pandas
    # python314Packages.pip
    # python314Packages.pyside6

    # PHP 
    # php

    # Rust
    rustc
    rustfmt
    cargo
    clippy

    # C / C++
    gcc
    gnumake
    cmake
    pkg-config
    ninja

    # Qt / QML
    qt6.qttools
    qt6.qtbase
    qt6.qmake
    qt6.qtquick3d
    qt6.qtdeclarative 

    # Editors / utilities
    vscodium-fhs
    vim
    curl
    wget
    #tree

    # Agents
    
    ## Wayland
    #  wayland-protocols
    #  wayland.dev
    #  waylandpp

    #Installer
  ];
}
