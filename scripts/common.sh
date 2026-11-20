# ── Rutas y estado ──
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nix-home"
BACKUP_DIR="$DATA_DIR/backups"
STATE_FILE="$DATA_DIR/state"
HW_COPY="$DATA_DIR/hardware-configuration.nix"
STAMP="$(date +%Y%m%d-%H%M%S)"

ORIG_USER="oozenix"
ORIG_DESC="OozeNix"
ORIG_HOST="nixos"
ORIG_TZ="America/Phoenix"
ORIG_LOCALE="en_US.UTF-8"
ORIG_KB="us"
ORIG_GPU="nvidia"

SUDO_READY=false
SUDO_PID=""
NIX_OPTS=()
FAILED=()
GEN_BEFORE=""
GEN_AFTER=""
APPLIED_MODE=""
EDITED=false
EDIT_FILES=()
EDIT_EXPRS=()
EDIT_RESULT=""

state_get() {
  if [ ! -f "$STATE_FILE" ]; then return 0; fi
  sed -n "s/^$1=//p" "$STATE_FILE" | head -n1 || true
}

state_set() {
  local tmp="$STATE_FILE.tmp"
  mkdir -p "$(dirname "$STATE_FILE")"
  if [ -f "$STATE_FILE" ]; then
    grep -v "^$1=" "$STATE_FILE" > "$tmp" || true
  else
    : > "$tmp"
  fi
  echo "$1=$2" >> "$tmp"
  mv -f "$tmp" "$STATE_FILE"
}

save_state() {
  state_set user "$(cur_user)"
  state_set desc "$(cur_desc)"
  state_set host "$(cur_host)"
  state_set tz "$(cur_tz)"
  state_set locale "$(cur_locale)"
  state_set kb "$(cur_kb)"
  state_set gpu "$(cur_gpu)"
}

# ── Sudo ──
sudo_keepalive_start() {
  if $SUDO_READY; then return 0; fi
  if ! sudo -v; then
    ui_err "Falló la autenticación de sudo."
    exit 1
  fi
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
  SUDO_PID=$!
  SUDO_READY=true
}

# ── Valores actuales del repositorio ──
nix_value() {
  { sed -n "s/^[[:space:]]*$2 = \"\\(.*\\)\";.*/\\1/p" "$REPO/$1" 2>/dev/null | head -n1; } || true
}

cur_user() { nix_value home/default.nix 'home\.username'; }
cur_desc() { nix_value modules/users.nix 'description'; }
cur_host() { nix_value modules/networking.nix 'networking\.hostName'; }
cur_tz() { nix_value modules/networking.nix 'time\.timeZone'; }
cur_locale() { nix_value modules/networking.nix 'i18n\.defaultLocale'; }
cur_kb() { nix_value modules/networking.nix 'layout'; }

cur_flake() {
  { sed -n 's/^[[:space:]]*nixosConfigurations\.\([A-Za-z0-9_-]*\) =.*/\1/p' "$REPO/flake.nix" 2>/dev/null | head -n1; } || true
}

gpu_enabled() {
  grep -qE "^[[:space:]]*\./modules/$1\.nix" "$REPO/configuration.nix" 2>/dev/null
}

cur_gpu() {
  local n=false a=false
  if gpu_enabled nvidia; then n=true; fi
  if gpu_enabled amdgpu; then a=true; fi
  if $n && $a; then echo both
  elif $n; then echo nvidia
  elif $a; then echo amd
  else echo none
  fi
}

# ── Detección del equipo ──
detect_user() { id -un; }

detect_fullname() {
  local n
  n="$(getent passwd "$(id -un)" | cut -d: -f5 | cut -d, -f1 || true)"
  printf '%s' "${n:-$(id -un)}"
}

detect_host() { cat /proc/sys/kernel/hostname 2>/dev/null || true; }

detect_tz() {
  local tz
  tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
  if [ -z "$tz" ] && [ -L /etc/localtime ]; then
    tz="$(readlink /etc/localtime | sed 's|.*zoneinfo/||')"
  fi
  printf '%s' "$tz"
}

detect_locale() {
  case "${LANG:-}" in
    ""|C|POSIX|C.UTF-8) return 0 ;;
  esac
  printf '%s' "$LANG"
}

detect_kb() {
  { localectl status 2>/dev/null | sed -n 's/.*X11 Layout: *//p' | head -n1; } || true
}

detect_gpus() {
  local v id out=""
  for v in /sys/class/drm/card[0-9]/device/vendor; do
    [ -r "$v" ] || continue
    id="$(cat "$v")"
    case "$id" in
      0x10de) out+="nvidia " ;;
      0x1002) out+="amd " ;;
      0x8086) out+="intel " ;;
    esac
  done
  printf '%s' "$out" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//'
}

flakes_enabled() {
  local cfg
  cfg="$(nix --extra-experimental-features 'nix-command flakes' config show experimental-features 2>/dev/null || true)"
  case "$cfg" in *flakes*) return 0 ;; esac
  return 1
}

# ── Validaciones ──
valid_user() { [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; }
valid_host() { [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]]; }
valid_tz() { [[ "$1" =~ ^[A-Za-z0-9_+/-]+$ ]]; }
valid_locale() { [[ "$1" =~ ^[A-Za-z0-9_.@-]+$ ]]; }
valid_kb() { [[ "$1" =~ ^[A-Za-z0-9_,-]+$ ]]; }
valid_text() { [[ -n "$1" && "$1" != *'"'* && "$1" != *'\'* && "$1" != *'$'* ]]; }

# ── Edición con vista previa ──
esc_re() { printf '%s' "$1" | sed -e 's/[][\.*^$+?(){}|/]/\\&/g'; }
esc_rep() { printf '%s' "$1" | sed -e 's/[\\&/]/\\&/g'; }

nix_files() {
  if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$REPO" ls-files '*.nix'
  else
    (cd "$REPO" && find . -name '*.nix' -not -path './.git/*' | sed 's|^\./||')
  fi
}

backup_file() {
  mkdir -p "$BACKUP_DIR/$(dirname "$1")"
  if [ ! -e "$BACKUP_DIR/$1.bak-${STAMP}" ]; then
    cp -f "$REPO/$1" "$BACKUP_DIR/$1.bak-${STAMP}"
  fi
}

show_diff() {
  local max="${3:-0}"
  {
    diff -U0 --label a --label b "$1" "$2" | awk -v r="$C_RED" -v g="$C_GREEN" -v d="$C_DIM" -v z="$C_RESET" '
      NR <= 2 { next }
      /^@@/ { print "        " d $0 z; next }
      /^-/ { print "        " r $0 z; next }
      /^\+/ { print "        " g $0 z; next }'
  } > "${2}.view" || true
  if [ "$max" -gt 0 ]; then
    head -n "$max" "${2}.view" || true
  else
    cat "${2}.view"
  fi
  rm -f "${2}.view"
}

edit_add() {
  EDIT_FILES+=("$1")
  EDIT_EXPRS+=("$2")
}

edit_run() {
  local title="$1" i f tmp
  local idx=()
  shift
  for i in "${!EDIT_FILES[@]}"; do
    f="${EDIT_FILES[$i]}"
    [ -f "$REPO/$f" ] || continue
    tmp="$(mktemp)"
    sed -E "${EDIT_EXPRS[$i]}" "$REPO/$f" > "$tmp"
    if ! cmp -s "$tmp" "$REPO/$f"; then
      idx+=("$i")
      printf '      %s%s%s\n' "$C_BOLD" "$f" "$C_RESET"
      show_diff "$REPO/$f" "$tmp"
    fi
    rm -f "$tmp" "$tmp.view"
  done
  if [ "${#idx[@]}" -eq 0 ]; then
    EDIT_RESULT="none"
  elif ask_yes_no "$title" y "$@" "El original se guarda en $BACKUP_DIR."; then
    for i in "${idx[@]}"; do
      f="${EDIT_FILES[$i]}"
      backup_file "$f"
      sed -E -i "${EDIT_EXPRS[$i]}" "$REPO/$f"
      ui_ok "Actualizado: $f"
    done
    EDITED=true
    EDIT_RESULT="done"
  else
    ui_more "Omitido."
    EDIT_RESULT="skipped"
  fi
  EDIT_FILES=()
  EDIT_EXPRS=()
}

# ── Cambios de identidad ──
apply_assign() {
  local file="$1" key="$2" new="$3" label="$4"
  edit_add "$file" "s/^([[:space:]]*$(esc_re "$key") = \")[^\"]*(\";)/\\1$(esc_rep "$new")\\2/"
  edit_run "¿Cambiar $label a '$new'?" "Archivo: $file"
}

apply_user() {
  local old="$1" new="$2" f
  while IFS= read -r f; do
    if grep -qwF -- "$old" "$REPO/$f" 2>/dev/null; then
      edit_add "$f" "s/\\b$(esc_re "$old")\\b/$(esc_rep "$new")/g"
    fi
  done < <(nix_files)
  edit_run "¿Reemplazar el usuario '$old' por '$new'?" \
    "Cambia el nombre del usuario y su carpeta (/home/$old)."
}

apply_user_all() {
  local new="$1" old seen=" "
  for old in "$(cur_user)" "$ORIG_USER"; do
    if [ -z "$old" ] || [ "$old" = "$new" ]; then continue; fi
    case "$seen" in *" $old "*) continue ;; esac
    seen+="$old "
    apply_user "$old" "$new"
  done
}

apply_host() {
  local new="$1" rep
  rep="$(esc_rep "$new")"
  edit_add modules/networking.nix "s/^([[:space:]]*networking\\.hostName = \")[^\"]*(\";)/\\1${rep}\\2/"
  edit_add flake.nix "s/^([[:space:]]*nixosConfigurations\\.)[A-Za-z0-9_-]+( =)/\\1${rep}\\2/"
  edit_run "¿Usar '$new' como nombre del equipo?" \
    "Cambia networking.hostName y nixosConfigurations en flake.nix." \
    "Los comandos de compilación usarán .#$new"
}

expr_enable() { echo "s/^([[:space:]]*)#[[:space:]]*(\\.\\/modules\\/$1\\.nix)/\\1\\2/"; }
expr_disable() { echo "s/^([[:space:]]*)(\\.\\/modules\\/$1\\.nix)/\\1#\\2/"; }

apply_gpu() {
  local want="$1" label
  case "$want" in
    nvidia)
      label="NVIDIA"
      edit_add configuration.nix "$(expr_enable nvidia);$(expr_disable amdgpu)"
      edit_add modules/programs/obs.nix 's/^([[:space:]]*cudaSupport = )false;/\1true;/'
      ;;
    amd)
      label="AMD"
      edit_add configuration.nix "$(expr_enable amdgpu);$(expr_disable nvidia)"
      edit_add modules/programs/obs.nix 's/^([[:space:]]*cudaSupport = )true;/\1false;/'
      ;;
    *)
      label="Intel u otra"
      edit_add configuration.nix "$(expr_disable nvidia);$(expr_disable amdgpu)"
      edit_add modules/programs/obs.nix 's/^([[:space:]]*cudaSupport = )true;/\1false;/'
      ;;
  esac
  edit_run "¿Configurar la GPU como $label?" \
    "Activa un solo módulo de GPU y ajusta CUDA en OBS para que coincida."
}

# ── Git ──
git_register_new() {
  local files=() f
  if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then return 0; fi
  mapfile -t files < <(git -C "$REPO" ls-files --others --exclude-standard)
  if [ "${#files[@]}" -eq 0 ]; then return 0; fi
  ui_info "Archivos nuevos que los flakes no ven hasta registrarlos en git:"
  for f in "${files[@]:0:8}"; do ui_more "$f"; done
  if [ "${#files[@]}" -gt 8 ]; then ui_more "... y $((${#files[@]} - 8)) más"; fi
  if ask_yes_no "¿Registrarlos en git (git add)?" y \
    "Solo los añade al índice; no crea ningún commit."; then
    git -C "$REPO" add -- "${files[@]}"
    ui_ok "Archivos registrados"
  fi
}

# ── Compilación ──
sys_gen() {
  ls -1 /nix/var/nix/profiles 2>/dev/null | sed -n 's/^system-\([0-9]*\)-link$/\1/p' | sort -n | tail -n1 || true
}

nixos_rebuild() {
  sudo nixos-rebuild "$1" --flake "$REPO#$(cur_flake)" "${NIX_OPTS[@]}"
}

rebuild_flow() {
  local choice mode default=3
  GEN_BEFORE="$(sys_gen)"
  if [ -z "$(cur_flake)" ]; then
    ui_err "No se encontró nixosConfigurations en flake.nix."
    FAILED+=("flake (sin nixosConfigurations)")
    return 1
  fi
  git_register_new
  sudo_keepalive_start
  ui_task "Comprobando que la configuración compile (dry-build)"
  if ! nixos_rebuild dry-build; then
    ui_err "La configuración no compila. El sistema no cambió."
    ui_more "Revisa el error de arriba. Tus respaldos están en $BACKUP_DIR."
    FAILED+=("compilación (dry-build)")
    return 1
  fi
  ui_ok "La configuración compila"

  if $ASSUME_YES; then
    ui_info "Con --yes no se aplica el sistema. Hazlo tú con:"
    ui_more "sudo nixos-rebuild boot --flake $REPO#$(cur_flake)"
    return 0
  fi

  if [ -n "${WAYLAND_DISPLAY:-}${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then default=1; fi
  ask_choice choice "¿Cómo quieres aplicarla?" "$default" \
    "Los cambios de escritorio o de la pantalla de inicio pueden cerrar tu sesión." \
    "Con 'boot' no se toca la sesión actual: se activa al reiniciar." \
    -- "boot · aplicar en el próximo arranque (recomendado)" \
       "test · probar ahora sin dejarla como predeterminada" \
       "switch · aplicar ahora y dejarla como predeterminada" \
       "No aplicar todavía"
  case "$choice" in
    boot*) mode=boot ;;
    test*) mode=test ;;
    switch*) mode=switch ;;
    *)
      ui_info "No se aplicó nada. Cuando quieras: sudo nixos-rebuild boot --flake $REPO#$(cur_flake)"
      return 0
      ;;
  esac

  ui_task "Ejecutando nixos-rebuild $mode"
  if nixos_rebuild "$mode"; then
    APPLIED_MODE="$mode"
    GEN_AFTER="$(sys_gen)"
    ui_ok "Configuración aplicada ($mode)"
  else
    FAILED+=("nixos-rebuild $mode")
    ui_err "Falló nixos-rebuild $mode."
    ui_more "Para volver atrás: sudo nixos-rebuild switch --rollback"
    return 1
  fi
  if [ "$mode" = "boot" ] && ask_yes_no "¿Reiniciar ahora?" n \
    "La nueva configuración se activa en el próximo arranque."; then
    systemctl reboot
  fi
}
