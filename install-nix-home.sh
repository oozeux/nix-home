#!/usr/bin/env bash

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_YES=false
NO_APPLY=false
ARGS_GIVEN=false

source "$REPO/scripts/ui.sh"
source "$REPO/scripts/common.sh"

# ── Argumentos ──
usage() {
  cat << 'EOF'
Uso: install-nix-home.sh [opciones]

  Pregunta antes de cada cambio y respalda cada archivo que modifica.

  --no-apply  Personaliza los archivos pero no compila ni aplica el sistema
  -y, --yes   No pregunta; usa la respuesta sugerida (nunca aplica el sistema)
  -h, --help  Muestra esta ayuda
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    ARGS_GIVEN=true
    case "$1" in
      --no-apply) NO_APPLY=true ;;
      -y|--yes) ASSUME_YES=true ;;
      -h|--help) usage; exit 0 ;;
      *) ui_err "Opción desconocida: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

on_exit() {
  local rc=$?
  if [ -n "$SUDO_PID" ]; then kill "$SUDO_PID" 2>/dev/null || true; fi
  ui_cursor_show
  if [ "$rc" -ne 0 ] && $EDITED; then
    ui_warn "Se detuvo antes de terminar. Tus respaldos están en: $BACKUP_DIR"
  fi
}
trap on_exit EXIT
trap 'exit 130' INT

# ── Revisión ──
pre_checks() {
  local ver

  if [ "$(id -u)" -eq 0 ]; then
    ui_err "No ejecutes el instalador como root. Úsalo con tu usuario normal."
    exit 1
  fi
  if ! grep -qE '^ID="?nixos"?$' /etc/os-release 2>/dev/null; then
    ui_err "Este instalador es solo para NixOS."
    exit 1
  fi
  ver="$(. /etc/os-release; printf '%s' "${VERSION_ID:-}")"
  case "$ver" in
    26.05*) ui_ok "NixOS $ver" ;;
    *) ui_warn "Tienes NixOS ${ver:-desconocido}; este repositorio apunta a 26.05." ;;
  esac

  if [ "$(uname -m)" != "x86_64" ]; then
    ui_warn "Arquitectura $(uname -m): el flake está definido para x86_64-linux."
  fi
  if [ ! -d /sys/firmware/efi ]; then
    ui_warn "No se detectó arranque UEFI; boot.nix usa systemd-boot y lo necesita."
  fi

  local tool
  for tool in sudo git nix nixos-rebuild; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      ui_err "Falta '$tool'."
      if [ "$tool" = "git" ]; then ui_more "Prueba: nix shell nixpkgs#git -c $0"; fi
      exit 1
    fi
  done

  if [ ! -f "$REPO/flake.nix" ] || [ ! -f "$REPO/configuration.nix" ]; then
    ui_err "No parece el repositorio nix-home: faltan flake.nix o configuration.nix en $REPO"
    exit 1
  fi
  ui_ok "Repositorio: $REPO"

  if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ui_warn "Esta carpeta no es un repositorio git (¿la descargaste como ZIP?)."
    if ask_yes_no "¿Inicializar git aquí?" y \
      "Los flakes solo ven archivos registrados en git." \
      "Para recibir actualizaciones después, clona el repositorio en su lugar."; then
      git -C "$REPO" init -q
      git -C "$REPO" add -A
      ui_ok "Repositorio git inicializado"
    else
      ui_err "Sin git no se puede compilar el flake."
      exit 1
    fi
  fi

  if flakes_enabled; then
    ui_ok "Flakes habilitados"
  else
    NIX_OPTS=(--option experimental-features "nix-command flakes")
    ui_warn "Flakes no está habilitado en este sistema; se activa solo para esta ejecución."
  fi
}

# ── Usuario ──
phase_user() {
  local new cur desc cur_d
  new="$(detect_user)"
  cur="$(cur_user)"
  ui_info "Usuario de este equipo: $new"
  ui_info "Usuario escrito en el repositorio: ${cur:-no encontrado}"

  if ! valid_user "$new"; then
    ui_warn "'$new' no es un nombre válido para NixOS; edítalo a mano."
    return 0
  fi
  apply_user_all "$new"
  if [ "$(cur_user)" = "$new" ]; then
    ui_ok "El repositorio usa el usuario '$new'"
  else
    ui_warn "El repositorio sigue con '$(cur_user)'. El sistema no tendrá tu usuario hasta que coincidan."
  fi

  desc="$(detect_fullname)"
  cur_d="$(cur_desc)"
  if [ "$desc" = "$cur_d" ]; then
    ui_ok "Nombre visible ya coincide ($desc)"
  elif valid_text "$desc"; then
    apply_assign modules/users.nix description "$desc" "el nombre visible del usuario"
  fi
}

# ── Host ──
phase_host() {
  local new cur flake
  new="$(detect_host)"
  cur="$(cur_host)"
  flake="$(cur_flake)"
  ui_info "Nombre de este equipo: ${new:-no detectado}"
  ui_info "En el repositorio: hostName=$cur · flake=$flake"

  if [ -z "$new" ] || ! valid_host "$new"; then
    ui_warn "No se pudo usar el nombre detectado; edita networking.nix y flake.nix a mano."
    return 0
  fi
  if [ "$cur" = "$new" ] && [ "$flake" = "$new" ]; then
    ui_ok "El nombre del equipo ya coincide ($new)"
    return 0
  fi
  apply_host "$new"
}

# ── Sistema ──
sys_setting() {
  local label="$1" file="$2" key="$3" det="$4" cur="$5" check="$6"
  if [ -z "$det" ]; then
    ui_info "No se pudo detectar $label; se deja '$cur'."
    return 0
  fi
  if [ "$det" = "$cur" ]; then
    ui_ok "${label^} ya coincide ($cur)"
    return 0
  fi
  if ! "$check" "$det"; then
    ui_warn "Formato inesperado en $label ('$det'); se deja '$cur'."
    return 0
  fi
  ui_info "Detectado para $label: $det (el repositorio trae: $cur)"
  apply_assign "$file" "$key" "$det" "$label"
}

phase_system() {
  sys_setting "la zona horaria" modules/networking.nix time.timeZone "$(detect_tz)" "$(cur_tz)" valid_tz
  sys_setting "el idioma" modules/networking.nix i18n.defaultLocale "$(detect_locale)" "$(cur_locale)" valid_locale
  sys_setting "la distribución del teclado" modules/networking.nix layout "$(detect_kb)" "$(cur_kb)" valid_kb
}

# ── Hardware ──
regen_hardware() {
  local tmp target="$REPO/hardware-configuration.nix"
  tmp="$(mktemp)"
  sudo_keepalive_start
  ui_task "Generando la configuración de hardware de este equipo"
  if ! sudo nixos-generate-config --show-hardware-config > "$tmp"; then
    rm -f "$tmp"
    FAILED+=("hardware-configuration.nix (nixos-generate-config)")
    return 0
  fi
  if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
    ui_ok "hardware-configuration.nix ya corresponde a este equipo"
    mkdir -p "$DATA_DIR"
    cp -f "$tmp" "$HW_COPY"
    rm -f "$tmp"
    return 0
  fi
  if [ -f "$target" ]; then
    ui_info "El archivo del repositorio difiere (normalmente es de otra máquina):"
    cp -f "$tmp" "$tmp.new"
    show_diff "$target" "$tmp.new" 14
    rm -f "$tmp.new"
  fi
  if ask_yes_no "¿Reemplazar hardware-configuration.nix por el de este equipo?" y \
    "Sin esto el sistema puede no arrancar: discos y módulos son de otra máquina." \
    "El original se guarda en $BACKUP_DIR."; then
    if [ -f "$target" ]; then backup_file hardware-configuration.nix; fi
    cat "$tmp" > "$target"
    mkdir -p "$DATA_DIR"
    cp -f "$tmp" "$HW_COPY"
    EDITED=true
    ui_ok "hardware-configuration.nix actualizado"
  else
    ui_warn "Se conserva el archivo del repositorio. Revísalo a mano antes de aplicar."
  fi
  rm -f "$tmp"
}

phase_hardware() {
  local found def=1 choice want
  found="$(detect_gpus)"
  ui_info "GPU detectada: ${found:-ninguna reconocida}"
  case " $found " in
    *" nvidia "*) def=1 ;;
    *" amd "*) def=2 ;;
    *) def=3 ;;
  esac
  ask_choice choice "¿Qué GPU debe usar la configuración?" "$def" \
    "Solo debe quedar activo un módulo de GPU." \
    -- "NVIDIA (modules/nvidia.nix)" "AMD (modules/amdgpu.nix)" "Intel u otra (sin módulo de GPU)"
  case "$choice" in
    NVIDIA*) want=nvidia ;;
    AMD*) want=amd ;;
    *) want=none ;;
  esac
  apply_gpu "$want"
  if [ "$EDIT_RESULT" = "none" ]; then ui_ok "La GPU ya está configurada como '$(cur_gpu)'"; fi
  regen_hardware
}

# ── Compilación ──
phase_build() {
  ui_info "Se compila primero sin activar nada; solo después eliges cómo aplicarla."
  rebuild_flow || true
}

# ── Opcional ──
phase_optional() {
  if [ ! -f "$REPO/installer/run.sh" ]; then
    ui_info "Este repositorio no incluye el instalador gráfico de paquetes."
    return 0
  fi
  if [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    ui_info "Sin sesión gráfica: el instalador gráfico de paquetes se abre más tarde con ./installer/run.sh"
    return 0
  fi
  if ask_yes_no "¿Abrir el instalador gráfico de paquetes?" n \
    "Sirve para buscar y editar los paquetes de la configuración."; then
    if command -v quickshell >/dev/null 2>&1; then
      setsid -f bash "$REPO/installer/run.sh" >/dev/null 2>&1
      ui_ok "Instalador gráfico abierto"
    else
      ui_info "Falta QuickShell. Ejecuta: nix shell nixpkgs#quickshell nixpkgs#nix-search-cli -c $REPO/installer/run.sh"
    fi
  fi
}

# ── Resumen ──
summary() {
  local f
  ui_rule
  if [ "${#FAILED[@]}" -gt 0 ]; then
    ui_big "CASI LISTO" 2 yellow
    ui_center "La instalación terminó, pero faltó algo" "$C_BOLD"
    echo
    ui_warn "Estos pasos NO se completaron:"
    for f in "${FAILED[@]}"; do ui_more "- $f"; done
  else
    ui_big "LISTO" 2 green
    ui_center "Nix Home quedó personalizado" "$C_BOLD"
  fi
  echo
  ui_row "Usuario" "$(cur_user)"
  ui_row "Equipo" "$(cur_flake)"
  ui_row "Zona horaria" "$(cur_tz)"
  ui_row "Idioma" "$(cur_locale)"
  ui_row "Teclado" "$(cur_kb)"
  ui_row "GPU" "$(cur_gpu)"
  if [ -n "$APPLIED_MODE" ]; then
    ui_row "Sistema" "aplicado ($APPLIED_MODE)"
  else
    ui_row "Sistema" "sin aplicar"
  fi
  if [ -n "$GEN_BEFORE" ] && [ -n "$GEN_AFTER" ] && [ "$GEN_BEFORE" != "$GEN_AFTER" ]; then
    ui_row "Generación" "$GEN_BEFORE -> $GEN_AFTER"
  fi
  echo
  printf '  %sVolver atrás:%s  sudo nixos-rebuild switch --rollback\n' "$C_BOLD" "$C_RESET"
  printf '  %sActualizar:%s    ./update-nix-home.sh\n' "$C_BOLD" "$C_RESET"
}

# ── Principal ──
main() {
  parse_args "$@"
  ui_hero "NIX HOME" "Instalador · NixOS + Hyprland"
  ui_intro "Te pregunto antes de cada cambio: nada se modifica sin tu confirmación." \
    "Cada archivo que se edita se respalda en $BACKUP_DIR."

  if $NO_APPLY; then UI_PHASE_TOTAL=6; else UI_PHASE_TOTAL=7; fi

  ui_phase "Revisando" "REVISANDO"
  pre_checks
  if ! ask_yes_no "¿Continuar con la personalización?" y \
    "Se edita este repositorio (usuario, equipo, sistema y hardware)."; then
    ui_info "Cancelado. No se cambió nada."
    exit 0
  fi

  ui_phase "Usuario" "USUARIO"
  phase_user

  ui_phase "Equipo" "EQUIPO"
  phase_host

  ui_phase "Sistema" "SISTEMA"
  phase_system

  ui_phase "Hardware" "HARDWARE"
  phase_hardware

  save_state

  if ! $NO_APPLY; then
    ui_phase "Compilar" "COMPILAR"
    phase_build
  fi

  ui_phase "Opcional" "OPCIONAL"
  phase_optional

  summary
}

main "$@"
