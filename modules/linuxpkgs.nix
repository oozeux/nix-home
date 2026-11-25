{ pkgs, inputs, ... }:

{
  # Enable AppImage Support
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.icu pkgs.libxcrypt-legacy ];
    };
  };

  # Module Linux Packages
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # X11 / Wayland / Gráficos
    libX11
    libxcb
    libXcursor
    libXinerama
    libXrandr
    libXdamage
    libXcomposite
    libXfixes
    libXext
    libXtst
    libXrender
    libxscrnsaver
    libXi
    libSM
    libICE
    libxshmfence
    libxkbcommon
    libGL
    libGLU
    vulkan-loader

    # Sonido
    alsa-lib
    libpulseaudio

    # Runtime básico
    glib
    libva
    fontconfig
    freetype
    expat

    # C++ / GCC
    stdenv.cc.cc.lib

    # AppImage / FUSE
    fuse
    e2fsprogs

    # Extras para juegos y multimedia
    SDL2
    SDL2_image
    SDL2_mixer
    SDL2_ttf
    libvorbis
    libpng
    libjpeg
    libtiff

    # Compresión, red y utilidades
    zlib
    openssl
    curl
    libxml2
    bzip2
    xz
    util-linux
    libelf
    krb5

    # Escritorio y GTK
    gtk3
    pango
    cairo
    gdk-pixbuf
    harfbuzz
    gsettings-desktop-schemas

    # Electron/Chromium
    nspr
    nss
    cups
    at-spi2-core
    dbus
    libdrm
    libgbm
    libxcrypt-legacy

    # Qt6 
    libxcb-cursor
    libxcb-wm
    libxcb-util
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
  ];
}