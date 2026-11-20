# ── Interfaz ──
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) ;;
  *) export LC_ALL=C.UTF-8 ;;
esac
UI_COLOR=false
UI_TTY=false
UI_256=false
UI_NCOL="$(tput colors 2>/dev/null || echo 0)"
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "$UI_NCOL" -ge 8 ]; then
  UI_COLOR=true
fi
if $UI_COLOR && [ "$UI_NCOL" -ge 256 ]; then
  UI_256=true
fi
if [ -t 0 ] && [ -t 1 ]; then
  UI_TTY=true
fi

if $UI_COLOR; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_CYAN=$'\033[36m'
  C_BG_GREEN=$'\033[42;30m'
  C_BG_RED=$'\033[41;97m'
  C_BG_CYAN=$'\033[46;30m'
else
  C_RESET="" C_BOLD="" C_DIM="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN=""
  C_BG_GREEN="" C_BG_RED="" C_BG_CYAN=""
fi

UI_WIDTH="$(tput cols 2>/dev/null || echo 70)"
if [ "$UI_WIDTH" -gt 76 ]; then UI_WIDTH=76; fi
if [ "$UI_WIDTH" -lt 50 ]; then UI_WIDTH=50; fi

UI_STEP=0
UI_TOTAL=0
UI_PHASE=0
UI_PHASE_TOTAL=0
UI_KEY=""

declare -A UI_FONT=(
  ["A"]=".#./#.#/###/#.#/#.#"
  ["B"]="##./#.#/##./#.#/##."
  ["C"]=".##/#../#../#../.##"
  ["D"]="##./#.#/#.#/#.#/##."
  ["E"]="###/#../##./#../###"
  ["F"]="###/#../##./#../#.."
  ["G"]=".##/#../#.#/#.#/.##"
  ["H"]="#.#/#.#/###/#.#/#.#"
  ["I"]="###/.#./.#./.#./###"
  ["J"]="..#/..#/..#/#.#/.#."
  ["K"]="#.#/#.#/##./#.#/#.#"
  ["L"]="#../#../#../#../###"
  ["M"]="#.#/###/###/#.#/#.#"
  ["N"]="##./#.#/#.#/#.#/#.#"
  ["O"]="###/#.#/#.#/#.#/###"
  ["P"]="##./#.#/##./#../#.."
  ["Q"]="###/#.#/#.#/###/..#"
  ["R"]="##./#.#/##./#.#/#.#"
  ["S"]=".##/#../.#./..#/##."
  ["T"]="###/.#./.#./.#./.#."
  ["U"]="#.#/#.#/#.#/#.#/###"
  ["V"]="#.#/#.#/#.#/#.#/.#."
  ["W"]="#.#/#.#/###/###/#.#"
  ["X"]="#.#/#.#/.#./#.#/#.#"
  ["Y"]="#.#/#.#/.#./.#./.#."
  ["Z"]="###/..#/.#./#../###"
  ["0"]="###/#.#/#.#/#.#/###"
  ["1"]=".#./##./.#./.#./###"
  ["2"]="##./..#/.#./#../###"
  ["3"]="##./..#/.#./..#/##."
  ["4"]="#.#/#.#/###/..#/..#"
  ["5"]="###/#../##./..#/##."
  ["6"]=".##/#../###/#.#/###"
  ["7"]="###/..#/.#./.#./.#."
  ["8"]="###/#.#/###/#.#/###"
  ["9"]="###/#.#/###/..#/##."
  ["-"]=".../.../###/.../..."
  ["."]=".../.../.../.../.#."
  ["!"]=".#./.#./.#./.../.#."
  [" "]=".../.../.../.../..."
)

ui_repeat() {
  local i out=""
  for ((i = 0; i < $2; i++)); do out+="$1"; done
  printf '%s' "$out"
}

ui_ascii() {
  local t="$1" pair
  for pair in á:a é:e í:i ó:o ú:u ü:u ñ:n Á:A É:E Í:I Ó:O Ú:U Ü:U Ñ:N; do
    t="${t//${pair%%:*}/${pair##*:}}"
  done
  printf '%s' "$t"
}

ui_center() {
  local text="$1" style="${2:-}" left
  left=$(((UI_WIDTH - ${#text}) / 2))
  if [ "$left" -lt 0 ]; then left=0; fi
  printf '%*s%s%s%s\n' "$left" "" "$style" "$text" "$C_RESET"
}

ui_pad_center() {
  local text="$1" width="$2" left right
  left=$(((width - ${#text}) / 2))
  if [ "$left" -lt 0 ]; then left=0; fi
  right=$((width - ${#text} - left))
  if [ "$right" -lt 0 ]; then right=0; fi
  printf '%*s%s%*s' "$left" "" "$text" "$right" ""
}

ui_rule() {
  printf '\n%s%s%s\n' "$C_DIM" "$(ui_repeat '─' "$UI_WIDTH")" "$C_RESET"
}

ui_big() {
  local text scale="${2:-1}" tone="${3:-cyan}" n i r c ch g px width left line row paint
  local block space gap
  local colors=() rows=() fallback="$C_CYAN"
  text="$(ui_ascii "$1")"
  text="${text^^}"
  n=${#text}
  width=$((n * 4 * scale - scale))
  if [ "$width" -gt "$UI_WIDTH" ] && [ "$scale" -gt 1 ]; then
    scale=1
    width=$((n * 4 - 1))
  fi
  if [ "$width" -gt "$UI_WIDTH" ]; then
    printf '\n  %s%s%s\n' "$C_BOLD" "$1" "$C_RESET"
    return 0
  fi
  case "$tone" in
    green) colors=(82 46 40 34 28); fallback="$C_GREEN" ;;
    red) colors=(210 203 202 196 160); fallback="$C_RED" ;;
    yellow) colors=(226 220 214 208 202); fallback="$C_YELLOW" ;;
    *) colors=(87 51 45 39 33) ;;
  esac
  block="$(ui_repeat '█' "$scale")"
  space="$(ui_repeat ' ' "$scale")"
  gap="$space"
  left=$(((UI_WIDTH - width) / 2))
  printf '\n'
  for ((r = 0; r < 5; r++)); do
    line=""
    for ((i = 0; i < n; i++)); do
      ch="${text:i:1}"
      g="${UI_FONT[$ch]:-.../.../.../.../...}"
      IFS=/ read -ra rows <<< "$g"
      row="${rows[r]}"
      for ((c = 0; c < 3; c++)); do
        px="${row:c:1}"
        if [ "$px" = "#" ]; then line+="$block"; else line+="$space"; fi
      done
      line+="$gap"
    done
    if $UI_256; then
      paint=$'\033[38;5;'"${colors[r]}"'m'
    else
      paint="$fallback"
    fi
    printf '%*s%s%s%s\n' "$left" "" "$paint" "$line" "$C_RESET"
  done
}

ui_hero() {
  ui_big "$1" 2 "${3:-cyan}"
  printf '\n'
  ui_center "$2" "$C_DIM"
  printf '\n'
}

ui_bar() {
  local cur="$1" tot="$2" width=24 filled
  if [ "$tot" -le 0 ]; then return 0; fi
  filled=$((cur * width / tot))
  if [ "$filled" -gt "$width" ]; then filled="$width"; fi
  printf '%s%s%s%s%s %s%d%%%s' "$C_GREEN" "$(ui_repeat '█' "$filled")" "$C_DIM" \
    "$(ui_repeat '░' $((width - filled)))" "$C_RESET" "$C_BOLD" $((cur * 100 / tot)) "$C_RESET"
}

ui_phase() {
  local big="${2:-$1}"
  ui_rule
  ui_big "$big" 1 cyan
  if [ "$UI_PHASE_TOTAL" -gt 0 ]; then
    UI_PHASE=$((UI_PHASE + 1))
    printf '\n  %sFase %s de %s%s   %s\n' "$C_BOLD" "$UI_PHASE" "$UI_PHASE_TOTAL" "$C_RESET" \
      "$(ui_bar "$UI_PHASE" "$UI_PHASE_TOTAL")"
  fi
  printf '\n'
}

ui_step() {
  UI_STEP=$((UI_STEP + 1))
  printf '\n%s%s▶ PASO %s de %s · %s%s\n' "$C_BOLD" "$C_CYAN" "$UI_STEP" "$UI_TOTAL" "$1" "$C_RESET"
  printf '  %s\n' "$(ui_bar "$UI_STEP" "$UI_TOTAL")"
}

ui_intro() {
  local line
  for line in "$@"; do
    printf '  %s%s%s\n' "$C_DIM" "$line" "$C_RESET"
  done
}

ui_task() { printf '  %s•%s %s\n' "$C_BLUE" "$C_RESET" "$1"; }
ui_ok() { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
ui_warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
ui_err() { printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$1"; }
ui_info() { printf '  %si%s %s%s%s\n' "$C_BLUE" "$C_RESET" "$C_DIM" "$1" "$C_RESET"; }
ui_more() { printf '      %s\n' "$1"; }

ui_yn() {
  if "$1"; then printf 'Sí'; else printf 'No'; fi
}

ui_row() {
  local label="$1" value="$2" dots style
  dots=$((34 - ${#label}))
  if [ "$dots" -lt 3 ]; then dots=3; fi
  case "$value" in
    "Sí") style="$C_GREEN$C_BOLD" ;;
    "No") style="$C_DIM" ;;
    *) style="$C_CYAN$C_BOLD" ;;
  esac
  printf '    %s%s%s %s%s%s %s%s%s\n' "$C_BOLD" "$label" "$C_RESET" "$C_DIM" \
    "$(ui_repeat '·' $((dots - 1)))" "$C_RESET" "$style" "$value" "$C_RESET"
}

ui_cursor_hide() {
  if $UI_TTY; then printf '\033[?25l'; fi
}

ui_cursor_show() {
  if $UI_TTY; then printf '\033[?25h'; fi
}

ui_key() {
  local k rest=""
  if ! IFS= read -rsn1 k; then
    UI_KEY="eof"
    return 0
  fi
  case "$k" in
    $'\e')
      IFS= read -rsn2 -t 0.05 rest || true
      case "$rest" in
        '[A') UI_KEY="up" ;;
        '[B') UI_KEY="down" ;;
        '[C') UI_KEY="right" ;;
        '[D') UI_KEY="left" ;;
        *) UI_KEY="esc" ;;
      esac
      ;;
    "") UI_KEY="enter" ;;
    $'\t') UI_KEY="tab" ;;
    *) UI_KEY="$k" ;;
  esac
}

ui_auto() {
  [ "${ASSUME_YES:-false}" = true ] || [ "${QUICK:-false}" = true ]
}

ui_question() {
  local title="$1" line
  shift
  printf '\n  %s?%s %s%s%s\n' "$C_CYAN" "$C_RESET" "$C_BOLD" "$title" "$C_RESET"
  for line in "$@"; do
    printf '    %s%s%s\n' "$C_DIM" "$line" "$C_RESET"
  done
}

ui_button_line() {
  local row="$1" active="$2" label="$3" bg="$4" text
  case "$row" in
    0) text='╭──────────────╮' ;;
    1)
      if [ "$active" = true ]; then label="▶ $label ◀"; else label="  $label  "; fi
      text="│$(ui_pad_center "$label" 14)│"
      ;;
    *) text='╰──────────────╯' ;;
  esac
  if [ "$active" = true ]; then
    printf '%s%s%s' "$bg" "$C_BOLD" "$text"
  else
    printf '%s%s' "$C_DIM" "$text"
  fi
  printf '%s' "$C_RESET"
}

ui_buttons() {
  local sel="$1" redraw="$2" final="$3" row yes_on=false no_on=false
  if [ "$sel" -eq 0 ]; then yes_on=true; else no_on=true; fi
  if [ "$redraw" = true ]; then printf '\033[4A'; fi
  for row in 0 1 2; do
    printf '\r\033[2K      %s    %s\n' \
      "$(ui_button_line "$row" "$yes_on" "SÍ" "$C_BG_GREEN")" \
      "$(ui_button_line "$row" "$no_on" "NO" "$C_BG_RED")"
  done
  if [ "$final" = true ]; then
    if [ "$sel" -eq 0 ]; then
      printf '\r\033[2K    %s✓ Elegiste: Sí%s\n' "$C_GREEN" "$C_RESET"
    else
      printf '\r\033[2K    %s✓ Elegiste: No%s\n' "$C_DIM" "$C_RESET"
    fi
  else
    printf '\r\033[2K    %s←/→ elegir · Enter confirmar · S / N atajo%s\n' "$C_DIM" "$C_RESET"
  fi
}

ask_yes_no() {
  local title="$1" def="$2" sel=0 drawn=false reply hint
  shift 2
  ui_question "$title" "$@"
  if ui_auto; then
    printf '    %s› respuesta automática: %s%s\n' "$C_YELLOW" "$([ "$def" = y ] && echo Sí || echo No)" "$C_RESET"
    if [ "$def" = "y" ]; then return 0; else return 1; fi
  fi
  if ! $UI_TTY; then
    if [ "$def" = "y" ]; then hint="S/n"; else hint="s/N"; fi
    while true; do
      read -r -p "    ${C_YELLOW}›${C_RESET} [$hint] " reply || { echo; return 1; }
      case "${reply,,}" in
        "") if [ "$def" = "y" ]; then return 0; else return 1; fi ;;
        s|si|sí|y|yes) return 0 ;;
        n|no) return 1 ;;
        *) ui_warn "Responde s (sí) o n (no)." ;;
      esac
    done
  fi
  if [ "$def" != "y" ]; then sel=1; fi
  ui_cursor_hide
  while true; do
    ui_buttons "$sel" "$drawn" false
    drawn=true
    ui_key
    case "$UI_KEY" in
      left|up) sel=0 ;;
      right|down) sel=1 ;;
      tab) sel=$((1 - sel)) ;;
      s|S|y|Y) sel=0; break ;;
      n|N) sel=1; break ;;
      enter) break ;;
      eof) sel=1; break ;;
    esac
  done
  ui_buttons "$sel" true true
  ui_cursor_show
  if [ "$sel" -eq 0 ]; then return 0; else return 1; fi
}

ui_menu_draw() {
  local sel="$1" redraw="$2" final="$3" count="$4" i label inner pad
  shift 4
  local options=("$@")
  inner=$((UI_WIDTH - 8))
  if [ "$redraw" = true ]; then printf '\033[%dA' $((count + 1)); fi
  for ((i = 0; i < count; i++)); do
    label="${options[$i]}"
    pad=$((inner - ${#label}))
    if [ "$pad" -lt 0 ]; then pad=0; fi
    if [ "$i" -eq "$sel" ]; then
      printf '\r\033[2K    %s%s ▶ %d  %s%*s%s\n' "$C_BG_CYAN" "$C_BOLD" $((i + 1)) "$label" "$pad" "" "$C_RESET"
    else
      printf '\r\033[2K      %s%d%s  %s\n' "$C_DIM" $((i + 1)) "$C_RESET" "$label"
    fi
  done
  if [ "$final" = true ]; then
    printf '\r\033[2K    %s✓ Elegiste: %s%s\n' "$C_GREEN" "${options[$sel]}" "$C_RESET"
  else
    printf '\r\033[2K    %s↑/↓ moverte · Enter elegir · 1-%d atajo%s\n' "$C_DIM" "$count" "$C_RESET"
  fi
}

ask_choice() {
  local var="$1" title="$2" def="$3" reply i marker sel drawn=false count
  local help=() options=()
  shift 3
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    help+=("$1")
    shift
  done
  if [ "$#" -gt 0 ]; then shift; fi
  options=("$@")
  count=${#options[@]}
  sel=$((def - 1))

  ui_question "$title" "${help[@]}"

  if ui_auto; then
    printf '    %s› respuesta automática: %s%s\n' "$C_YELLOW" "${options[$sel]}" "$C_RESET"
    printf -v "$var" '%s' "${options[$sel]}"
    return 0
  fi
  if ! $UI_TTY; then
    for ((i = 0; i < count; i++)); do
      marker=""
      if [ "$i" -eq "$sel" ]; then marker=" ${C_DIM}(sugerida)${C_RESET}"; fi
      printf '    %s%d)%s %s%s\n' "$C_YELLOW" $((i + 1)) "$C_RESET" "${options[$i]}" "$marker"
    done
    while true; do
      read -r -p "    ${C_YELLOW}›${C_RESET} Número [$def]: " reply || { echo; reply=""; }
      reply="${reply:-$def}"
      if [[ "$reply" =~ ^[0-9]+$ ]] && [ "$reply" -ge 1 ] && [ "$reply" -le "$count" ]; then
        printf -v "$var" '%s' "${options[$((reply - 1))]}"
        return 0
      fi
      ui_warn "Escribe un número entre 1 y $count."
    done
  fi
  ui_cursor_hide
  while true; do
    ui_menu_draw "$sel" "$drawn" false "$count" "${options[@]}"
    drawn=true
    ui_key
    case "$UI_KEY" in
      up) sel=$(((sel + count - 1) % count)) ;;
      down|tab) sel=$(((sel + 1) % count)) ;;
      enter) break ;;
      eof) break ;;
      [1-9])
        if [ "$UI_KEY" -le "$count" ]; then sel=$((UI_KEY - 1)); break; fi
        ;;
    esac
  done
  ui_menu_draw "$sel" true true "$count" "${options[@]}"
  ui_cursor_show
  printf -v "$var" '%s' "${options[$sel]}"
}
