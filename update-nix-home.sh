#!/usr/bin/env bash

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_YES=false
CHECK=false
DEPS=false
FORCE=false
NO_APPLY=false
ARGS_GIVEN=false
STASHED=false
STASH_KEPT=false
PULL_FAILED=false
FLAKE_CHANGED=false
UPSTREAM=""
AHEAD=0
BEHIND=0
OLD_HEAD=""
NEW_HEAD=""
CHANGED_FILES=""

source "$REPO/scripts/ui.sh"
source "$REPO/scripts/common.sh"

# ── Argumentos ──
usage() {
  cat << 'EOF'
Uso: update-nix-home.sh [opciones]

  Sin opciones, en una terminal, se abre un menú para elegir qué hacer.

  --check      Solo informa si hay una actualización disponible
  --deps       También actualiza las dependencias del flake (nix flake update)
  --force      Continúa aunque no haya commits nuevos
  --no-apply   Actualiza el repositorio pero no compila ni aplica el sistema
  -y, --yes    No pregunta; usa la respuesta sugerida (nunca aplica el sistema)
  -h, --help   Muestra esta ayuda
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    ARGS_GIVEN=true
    case "$1" in
      --check) CHECK=true ;;
      --deps) DEPS=true ;;
      --force) FORCE=true ;;
      --no-apply) NO_APPLY=true ;;
      -y|--yes) ASSUME_YES=true ;;
      -h|--help) usage; exit 0 ;;
      *) ui_err "Opción desconocida: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

show_menu() {
  local choice
  ask_choice choice "¿Qué quieres hacer?" 1 \
    "Muévete con las flechas y pulsa Enter." \
    -- "Actualizar ahora (recomendado)" \
       "Solo buscar novedades (no cambia nada)" \
       "Actualizar y también las dependencias del flake" \
       "Salir"
  case "$choice" in
    "Solo buscar"*) CHECK=true ;;
    "Actualizar y también"*) DEPS=true ;;
    "Salir") ui_info "Cancelado. No se cambió nada."; exit 0 ;;
  esac
}

on_exit() {
  local rc=$?
  if [ -n "$SUDO_PID" ]; then kill "$SUDO_PID" 2>/dev/null || true; fi
  ui_cursor_show
  if [ "$rc" -ne 0 ]; then
    if $STASHED; then
      ui_warn "Se detuvo antes de terminar. Tus cambios locales están en el stash: git -C $REPO stash pop"
    fi
    if $EDITED; then
      ui_warn "Se detuvo antes de terminar. Tus respaldos están en: $BACKUP_DIR"
    fi
  fi
}
trap on_exit EXIT
trap 'exit 130' INT

changed_in() {
  printf '%s\n' "$CHANGED_FILES" | awk -v p="$1" 'index($0, p) == 1 { found = 1 } END { exit !found }'
}

# ── Revisión ──
pre_checks() {
  local gitdir tool

  if [ "$(id -u)" -eq 0 ]; then
    ui_err "No ejecutes el actualizador como root. Úsalo con tu usuario normal."
    exit 1
  fi
  if ! grep -qE '^ID="?nixos"?$' /etc/os-release 2>/dev/null; then
    ui_err "Este actualizador es solo para NixOS."
    exit 1
  fi
  for tool in sudo git nix nixos-rebuild; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      ui_err "Falta '$tool'."
      exit 1
    fi
  done
  if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ui_err "$REPO no es un repositorio git."
    ui_more "Clona el repositorio con git para poder recibir actualizaciones."
    exit 1
  fi
  gitdir="$(git -C "$REPO" rev-parse --absolute-git-dir)"
  if [ -e "$gitdir/MERGE_HEAD" ] || [ -d "$gitdir/rebase-merge" ] || [ -d "$gitdir/rebase-apply" ]; then
    ui_err "Hay un merge o rebase en curso en $REPO. Termínalo o abórtalo primero."
    exit 1
  fi
  if ! UPSTREAM="$(git -C "$REPO" rev-parse --abbrev-ref '@{u}' 2>/dev/null)"; then
    ui_err "La rama actual no tiene upstream."
    ui_more "Defínelo con: git -C $REPO branch --set-upstream-to=origin/main"
    exit 1
  fi
  if ! flakes_enabled; then
    NIX_OPTS=(--option experimental-features "nix-command flakes")
  fi
  if [ ! -f "$STATE_FILE" ]; then
    ui_info "No hay datos del instalador: se omite la reaplicación de tu usuario y equipo."
    ui_more "Ejecuta ./install-nix-home.sh para guardarlos."
  fi
  ui_ok "Repositorio: $REPO (sigue a $UPSTREAM)"
}

fetch_remote() {
  ui_task "Consultando $UPSTREAM"
  if ! git -C "$REPO" fetch --quiet; then
    ui_err "No se pudo conectar con el remoto. Revisa tu conexión."
    exit 1
  fi
  read -r AHEAD BEHIND < <(git -C "$REPO" rev-list --left-right --count "HEAD...@{u}")
  if [ "$BEHIND" -gt 0 ]; then
    ui_info "$BEHIND commit(s) nuevos disponibles:"
    git -C "$REPO" log --oneline --no-decorate -n 10 "HEAD..@{u}" | sed 's/^/      /'
    if [ "$BEHIND" -gt 10 ]; then ui_more "... y $((BEHIND - 10)) más"; fi
  else
    ui_ok "No hay commits nuevos en $UPSTREAM"
  fi
  if [ "$AHEAD" -gt 0 ]; then
    ui_info "Tienes $AHEAD commit(s) locales sin subir."
  fi
}

# ── Repositorio ──
stash_local() {
  if [ -n "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]; then
    git -C "$REPO" stash push --quiet -m "nix-home-update-${STAMP}"
    STASHED=true
    ui_ok "Tus cambios locales se apartaron (stash)"
  fi
}

unstash_local() {
  if ! $STASHED; then return 0; fi
  if git -C "$REPO" stash pop --quiet; then
    ui_ok "Tus cambios locales se volvieron a aplicar"
  else
    git -C "$REPO" reset --hard --quiet HEAD
    STASH_KEPT=true
    ui_warn "Tus cambios locales chocan con la actualización."
    ui_more "El repositorio quedó limpio en la versión nueva; no se perdió nada,"
    ui_more "tus cambios siguen en el stash. Más abajo se reaplican tu usuario,"
    ui_more "equipo y hardware. Lo demás revísalo a mano:"
    ui_more "  git -C $REPO stash show -p"
    ui_more "  git -C $REPO stash pop"
  fi
  STASHED=false
}

pull_upstream() {
  if [ "$BEHIND" -eq 0 ]; then return 0; fi
  if [ "$AHEAD" -eq 0 ]; then
    if git -C "$REPO" merge --ff-only --quiet '@{u}'; then
      ui_ok "Avance rápido hasta $UPSTREAM"
      return 0
    fi
    ui_err "Falló el avance rápido."
    return 1
  fi
  ui_warn "Tu rama se separó de $UPSTREAM ($AHEAD locales, $BEHIND remotos)."
  if ask_yes_no "¿Hacer rebase de tus commits locales sobre los remotos?" n \
    "Si el rebase tiene conflictos se aborta y no cambia nada."; then
    if git -C "$REPO" rebase --quiet '@{u}'; then
      ui_ok "Rebase hecho sobre $UPSTREAM"
      return 0
    fi
    git -C "$REPO" rebase --abort || true
    ui_err "El rebase tuvo conflictos y se abortó. No se cambió nada."
    return 1
  fi
  ui_more "Omitido. Resuélvelo a mano: git -C $REPO pull --rebase"
  return 1
}

sync_repo() {
  OLD_HEAD="$(git -C "$REPO" rev-parse HEAD)"
  stash_local
  if ! pull_upstream; then PULL_FAILED=true; fi
  unstash_local
  NEW_HEAD="$(git -C "$REPO" rev-parse HEAD)"
  if [ "$OLD_HEAD" != "$NEW_HEAD" ]; then
    CHANGED_FILES="$(git -C "$REPO" diff --name-only "$OLD_HEAD" "$NEW_HEAD")"
  fi
}

# ── Tus valores ──
restore_hardware() {
  local target="$REPO/hardware-configuration.nix"
  if [ ! -f "$HW_COPY" ]; then return 0; fi
  if cmp -s "$HW_COPY" "$target"; then
    ui_ok "hardware-configuration.nix sigue siendo el de este equipo"
    return 0
  fi
  ui_warn "hardware-configuration.nix ya no coincide con el de este equipo."
  if ask_yes_no "¿Restaurar el de este equipo?" y \
    "Si se queda el del repositorio, el sistema puede no arrancar." \
    "El actual se guarda en $BACKUP_DIR."; then
    backup_file hardware-configuration.nix
    cat "$HW_COPY" > "$target"
    EDITED=true
    ui_ok "hardware-configuration.nix restaurado"
  fi
}

should_reapply() {
  if [ -z "$3" ] || [ "$1" = "$3" ]; then return 1; fi
  if $STASH_KEPT; then return 0; fi
  [ "$1" = "$2" ] && [ "$3" != "$2" ]
}

reapply_assign() {
  local file="$1" key="$2" label="$3" cur="$4" orig="$5" saved="$6"
  if should_reapply "$cur" "$orig" "$saved"; then
    apply_assign "$file" "$key" "$saved" "$label"
  fi
}

reapply_identity() {
  local saved f leftover=false

  restore_hardware
  if [ ! -f "$STATE_FILE" ]; then return 0; fi

  saved="$(state_get user)"
  if [ -n "$saved" ] && [ "$saved" != "$ORIG_USER" ]; then
    while IFS= read -r f; do
      if grep -qwF -- "$ORIG_USER" "$REPO/$f" 2>/dev/null; then leftover=true; fi
    done < <(nix_files)
    if $leftover; then apply_user "$ORIG_USER" "$saved"; fi
  fi

  reapply_assign modules/users.nix description "el nombre visible" "$(cur_desc)" "$ORIG_DESC" "$(state_get desc)"
  reapply_assign modules/networking.nix time.timeZone "la zona horaria" "$(cur_tz)" "$ORIG_TZ" "$(state_get tz)"
  reapply_assign modules/networking.nix i18n.defaultLocale "el idioma" "$(cur_locale)" "$ORIG_LOCALE" "$(state_get locale)"
  reapply_assign modules/networking.nix layout "el teclado" "$(cur_kb)" "$ORIG_KB" "$(state_get kb)"

  saved="$(state_get host)"
  if should_reapply "$(cur_host)" "$ORIG_HOST" "$saved" || should_reapply "$(cur_flake)" "$ORIG_HOST" "$saved"; then
    apply_host "$saved"
  fi

  saved="$(state_get gpu)"
  if should_reapply "$(cur_gpu)" "$ORIG_GPU" "$saved"; then
    case "$saved" in
      amd|nvidia|none) apply_gpu "$saved" ;;
    esac
  fi

  if ! $EDITED; then ui_ok "Tus valores ya están en su sitio"; fi
  save_state
}

# ── Dependencias ──
update_flake() {
  if ! $DEPS; then
    if ! ask_yes_no "¿Actualizar también las dependencias del flake (nix flake update)?" n \
      "Trae versiones nuevas de nixpkgs, Home Manager, Hyprland, etc." \
      "Tarda más y puede cambiar mucho; si algo falla, flake.lock se puede restaurar."; then
      return 0
    fi
  fi
  ui_task "Actualizando flake.lock"
  if (cd "$REPO" && nix flake update "${NIX_OPTS[@]}"); then
    FLAKE_CHANGED=true
    ui_ok "flake.lock actualizado"
    git -C "$REPO" diff --stat -- flake.lock | sed 's/^/      /' || true
    ui_more "Para deshacerlo: git -C $REPO checkout -- flake.lock"
  else
    FAILED+=("nix flake update")
    ui_warn "No se pudo actualizar el flake; se sigue con las versiones actuales."
  fi
}

# ── Resumen ──
summary() {
  local f
  ui_rule
  if [ "${#FAILED[@]}" -gt 0 ]; then
    ui_big "CASI LISTO" 2 yellow
    ui_center "La actualización terminó, pero faltó algo" "$C_BOLD"
    echo
    ui_warn "Estos pasos NO se completaron:"
    for f in "${FAILED[@]}"; do ui_more "- $f"; done
  else
    ui_big "LISTO" 2 green
    ui_center "Nix Home se actualizó correctamente" "$C_BOLD"
  fi
  echo
  if [ "$OLD_HEAD" != "$NEW_HEAD" ]; then
    ui_row "Repositorio" "${OLD_HEAD:0:7} -> ${NEW_HEAD:0:7}"
  fi
  if $FLAKE_CHANGED; then ui_row "flake.lock" "actualizado"; fi
  if $STASH_KEPT; then ui_row "Cambios locales" "siguen en el stash (mira el aviso de arriba)"; fi
  if [ -n "$APPLIED_MODE" ]; then ui_row "Sistema" "aplicado ($APPLIED_MODE)"; fi
  if [ -n "$GEN_BEFORE" ] && [ -n "$GEN_AFTER" ] && [ "$GEN_BEFORE" != "$GEN_AFTER" ]; then
    ui_row "Generación" "$GEN_BEFORE -> $GEN_AFTER"
  fi
  if changed_in "flake.nix"; then ui_row "flake.nix" "cambió: revisa los diffs del repositorio"; fi
  if changed_in "update-nix-home.sh" || changed_in "scripts/"; then
    ui_row "Actualizador" "cambió: ejecútalo otra vez para usar los pasos nuevos"
  fi
  if changed_in "install-nix-home.sh"; then
    ui_row "Instalador" "cambió: lee las diferencias si dependes de sus preguntas"
  fi
  echo
  printf '  %sVolver atrás:%s  sudo nixos-rebuild switch --rollback\n' "$C_BOLD" "$C_RESET"
}

# ── Principal ──
main() {
  parse_args "$@"
  ui_hero "NIX HOME" "Actualizador · NixOS + Hyprland"

  if ! $ARGS_GIVEN && $UI_TTY; then
    show_menu
  fi

  if $CHECK; then
    UI_PHASE_TOTAL=0
  elif $NO_APPLY; then
    UI_PHASE_TOTAL=4
  else
    UI_PHASE_TOTAL=5
  fi

  ui_phase "Revisando" "REVISANDO"
  pre_checks
  fetch_remote

  if $CHECK; then
    ui_rule
    if [ "$BEHIND" -gt 0 ]; then
      ui_big "HAY NOVEDADES" 1 yellow
      ui_center "Ejecuta update-nix-home.sh para aplicarlas" "$C_BOLD"
    else
      ui_big "AL DIA" 2 green
      ui_center "Ya está todo al día" "$C_BOLD"
    fi
    echo
    exit 0
  fi
  if [ "$BEHIND" -eq 0 ] && ! $FORCE && ! $DEPS; then
    ui_rule
    ui_big "AL DIA" 2 green
    ui_center "Ya está todo al día" "$C_BOLD"
    echo
    ui_info "Usa --deps para actualizar las dependencias del flake o --force para recompilar igualmente."
    exit 0
  fi

  ui_phase "Repositorio" "REPOSITORIO"
  sync_repo
  if $PULL_FAILED; then
    ui_err "El repositorio no se actualizó; se omitió el resto de la actualización."
    exit 1
  fi

  ui_phase "Tus valores" "TUS VALORES"
  reapply_identity

  ui_phase "Dependencias" "DEPENDENCIAS"
  update_flake

  if ! $NO_APPLY; then
    ui_phase "Compilar" "COMPILAR"
    rebuild_flow || true
  fi

  summary
}

main "$@"
