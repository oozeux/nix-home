{ config, pkgs, ... }:
# ─────────────────────────────────────────────────────────────
# GPU: AMD Radeon (RX 9060 XT) — driver open-source amdgpu
# ─────────────────────────────────────────────────────────────
{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;   # Necesario para juegos de 32 bits (Steam, Proton, Wine)
  };

  # Módulo del kernel para AMD. `
  hardware.amdgpu.initrd.enable = true;

  # Driver de video para Xorg/Wayland. 
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Soporte de OpenCL
  hardware.amdgpu.opencl.enable = true;

  # ─────────────────────────────────────────────────────────────
  # Opcional: herramientas útiles para monitorear/controlar la GPU
  # ─────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    radeontop     # monitor de uso de la GPU en tiempo real (como nvtop pero AMD)
    vulkan-tools  # vulkaninfo, vkcube — para verificar que Vulkan funciona
    clinfo        # para verificar OpenCL
  ];

}