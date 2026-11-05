# ❄️ Configuración de NixOS

Una configuración modular de NixOS que utiliza **Flakes** y **Home Manager**,
con Hyprland, niri, MangoWM, QuickShell, compatibilidad con NVIDIA,
herramientas para videojuegos y paquetes de desarrollo.

Este repositorio está adaptado a mi propio PC. **No lo apliques sin revisar
primero los ajustes específicos de tu máquina.** Mis dotfiles de escritorio
se mantienen por separado en
[dotfiles-nix](https://github.com/shizukutakahashi55-del/dotfiles-nix).

## Qué incluye

- **Gestores de ventanas:** Hyprland, niri y MangoWM.
- **Escritorio:** QuickShell, herramientas de bloqueo e inactividad, fondos
  de pantalla, capturas, utilidades del portapapeles y temas.
- **Sistema:** PipeWire, Bluetooth, NetworkManager, Flatpak, polkit y QEMU.
- **Gráficos:** controladores NVIDIA y configuración de OBS/CUDA. Puede haber
  una alternativa para AMD en los módulos.
- **Videojuegos:** Steam con Millennium, Lutris, herramientas de Wine/Proton,
  MangoHud y Prism Launcher.
- **Aplicaciones:** navegadores, comunicación, desarrollo, terminal,
  administración de archivos y herramientas multimedia configuradas con
  Home Manager.
- **Instalador:** una interfaz gráfica de QuickShell para editar archivos Nix
  compatibles, revisar cambios y compilar, probar y aplicar la configuración.

## Antes de instalar

Requisitos:

- Una instalación existente de **NixOS 26.05**.
- Arquitectura `x86_64-linux` y UEFI.
- Git y Flakes habilitados.

Esta configuración incluye valores específicos del hardware y del usuario.
Revisa, como mínimo, los siguientes archivos:

- `hardware-configuration.nix`
- `modules/users.nix` y `home/default.nix`
- `modules/networking.nix`
- `flake.nix` y `configuration.nix`
- Los módulos relacionados con la GPU y el sistema de archivos

## Instalación

### 1. Clona el repositorio

```bash
git clone https://github.com/shizukutakahashi55-del/nix-home.git ~/nix-home
cd ~/nix-home
```

### 2. Genera la configuración de hardware

No reutilices el archivo `hardware-configuration.nix` del repositorio en
otra máquina. Sustitúyelo por el correspondiente a tu instalación actual:

```bash
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

Revisa el archivo generado antes de continuar.

### 3. Cambia el nombre de usuario

Averigua tu nombre de usuario actual:

```bash
whoami
```

Sustituye el nombre de ejemplo `oozenix` por el tuyo en todos los lugares
donde esté escrito directamente (principalmente en `modules/users.nix` y
`home/default.nix`). Para encontrar todas las apariciones desde la raíz del
repositorio, ejecuta:

```bash
grep -RIn --exclude-dir=.git 'oozenix' .
```

No reemplaces todas las coincidencias a ciegas: comprueba si cada aparición
es un nombre de usuario, una ruta (`/home/oozenix`) o una cadena sin relación.

### 4. Adapta el resto de la configuración

Actualiza el nombre del equipo (hostname), la zona horaria, la configuración
regional, la GPU y cualquier ajuste específico del sistema de archivos para
que coincidan con tu máquina.

El flake define el equipo como `nixos`, por lo que los comandos de este README
utilizan `.#nixos`. Si cambias el nombre del equipo en `flake.nix`, actualiza
también los comandos según corresponda.

Si tu sistema utiliza AMD, revisa las importaciones de GPU en
`configuration.nix` y el módulo de OBS antes de compilar. No habilites ambas
configuraciones de GPU al mismo tiempo.

### 5. Añade los archivos nuevos a Git

Flakes solo detecta los archivos registrados en Git. Por eso, cualquier
archivo que crees o renombres debe añadirse al índice antes de reconstruir
la configuración. Primero revisa qué ha cambiado:

```bash
git status --short
```

Después, añade los archivos que quieras incluir:

```bash
git add hardware-configuration.nix configuration.nix flake.nix modules home
```

### 6. Compila y aplica la configuración

Comprueba que la configuración se pueda compilar:

```bash
sudo nixos-rebuild dry-build --flake .#nixos
```

Después, actívala:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Reinicia si es necesario. Home Manager está integrado en la configuración
de NixOS, así que no necesitas ejecutar `home-manager switch` por separado.

## Actualización

Para obtener los últimos cambios de este repositorio sin perder tus propias
modificaciones (nombre de usuario, configuración de hardware, etc.):

```bash
cd ~/nix-home
git stash            # guarda tus cambios locales
git pull             # descarga la versión más reciente
git stash pop        # vuelve a aplicar tus cambios
```

Si `git stash pop` informa de conflictos, abre los archivos marcados,
conserva los valores que correspondan a tu máquina y después ejecuta
`git add` sobre ellos.

Luego revisa los cambios y aplica la configuración:

```bash
git diff HEAD@{1} -- flake.lock     # opcional: muestra qué entradas cambiaron
sudo nixos-rebuild dry-build --flake .#nixos
sudo nixos-rebuild switch --flake .#nixos
```

Notas:

- Si la actualización añade archivos nuevos que mencionan `oozenix`, vuelve
  a ejecutar el comando `grep` del [paso 3](#3-cambia-el-nombre-de-usuario).
- Si descargaste el repositorio como ZIP en lugar de clonarlo, `git pull` no
  estará disponible. Descarga el ZIP nuevo y copia sobre él tus archivos
  modificados (`hardware-configuration.nix`, `modules/users.nix`,
  `home/default.nix`, etc.), o cambia a `git clone` para facilitar futuras
  actualizaciones.
- Si algo deja de funcionar, vuelve a la generación anterior con
  `sudo nixos-rebuild switch --rollback`.

## Comandos habituales

Ejecuta estos comandos desde el directorio del repositorio.

| Comando | Función |
|---|---|
| `nix flake update` | Actualiza las entradas del flake y vuelve a generar `flake.lock`. Ejecútalo solo si quieres actualizar las dependencias y revisa primero los cambios. |
| `sudo nixos-rebuild dry-build --flake .#nixos` | Comprueba si la configuración se puede compilar sin activarla. |
| `sudo nixos-rebuild build --flake .#nixos` | Compila la configuración del sistema sin activarla. |
| `sudo nixos-rebuild test --flake .#nixos` | Activa la configuración temporalmente; no se convertirá en la configuración predeterminada de arranque. |
| `sudo nixos-rebuild switch --flake .#nixos` | Compila y activa la configuración, y la establece como la generación actual del sistema. |
| `sudo nixos-rebuild boot --flake .#nixos` | Compila la configuración y la establece como predeterminada para el siguiente arranque, sin activarla ahora. |
| `sudo nixos-rebuild switch --rollback` | Vuelve a la generación anterior del sistema. |
| `git status --short` | Muestra los archivos modificados y los que aún no están registrados en Git. |
| `git diff` | Revisa los cambios que todavía no se han añadido al índice. |

**Consejo:** Los cambios en el compositor, el gestor de pantalla o la pantalla
de inicio de sesión pueden cerrar tu sesión gráfica. Aplícalos desde una TTY
o utiliza `sudo nixos-rebuild boot --flake .#nixos` y reinicia. Si la pantalla
de inicio de sesión falla, cambia a otra TTY (`Ctrl+Alt+F2`) y ejecuta
`sudo nixos-rebuild switch --rollback`.

## Instalador gráfico

El directorio `installer/` contiene una interfaz gráfica de QuickShell para
administrar los archivos `.nix` compatibles de este repositorio. Incluye
búsqueda y edición de paquetes, revisión de cambios, un editor de archivos
Nix y controles para validar, probar y aplicar cambios. Revisa cada cambio
antes de aplicarlo.

Si QuickShell y `nix-search-cli` aún no están disponibles, inicia el
instalador con:

```bash
nix shell -p quickshell nix-search-cli -c ./installer/run.sh
```

De lo contrario, ejecuta:

```bash
./installer/run.sh
```

Para mostrar u ocultar el instalador mediante una combinación de teclas:

```bash
./installer/toggle.sh
```

Para forzar su cierre incluso si hay un comando en ejecución:

```bash
./installer/toggle.sh --force
```

Por defecto, el backend de Rust se compila fuera del repositorio, en
`~/.cache/nix-home-installer/target`. Puedes cambiar la ubicación de
compilación mediante `CARGO_TARGET_DIR`.

## OozeLogin (pantalla de inicio de sesión)

`modules/greetd.nix` habilita OozeLogin, una pantalla de bienvenida de
QuickShell para greetd que cuenta con su propia ventana de ajustes.
Reemplaza a tuigreet. Encontrarás más detalles en
`modules/oozelogin/README.md`.

| Comando | Función |
|---|---|
| `oozelogin-settings` | Abre la ventana de ajustes (apariencia, paneles, acceso, clima y OozeShell). |
| `oozelogin-preview` | Ejecuta la pantalla de bienvenida en una ventana para probarla (contraseña de prueba: `ooze`). |
| `oozelogin-sync` | Copia los colores de OozeShell, el fondo de pantalla y el avatar a la pantalla de inicio de sesión. |

La opción `sync.enable = true` ejecuta la sincronización automáticamente
cada vez que cambian la paleta de matugen, el fondo de pantalla de awww o
el perfil de OozeShell. Tu usuario debe pertenecer al grupo `users` para
poder editar los ajustes de la pantalla de bienvenida. Prueba los cambios
con `oozelogin-preview` antes de aplicarlos.

## Estructura del repositorio

```text
.
├── flake.nix
├── flake.lock
├── configuration.nix
├── hardware-configuration.nix
├── modules/       # Módulos del sistema, controladores, servicios y OozeLogin
├── home/          # Configuración de Home Manager y aplicaciones del usuario
└── installer/     # Interfaz de QuickShell y backend de Rust
```

## Notas importantes

- **Versión del sistema:** Mantén `system.stateVersion` y
  `home.stateVersion` de Home Manager en las versiones utilizadas cuando se
  instaló el sistema por primera vez. No las cambies solo para actualizar
  NixOS.
- **Entorno NVIDIA:** `modules/nvidia.nix` establece variables de entorno
  relacionadas con los gráficos. Si la configuración de tu compositor
  establece esas mismas variables, asegúrate de que los valores coincidan.
- **Polkit:** Revisa `modules/polkit.nix`; define qué acciones privilegiadas
  de energía se pueden realizar sin contraseña.
- **Mantenimiento:** Revisa `modules/maintenance.nix` y asegúrate de que los
  ajustes de mantenimiento de Btrfs correspondan a tu sistema de archivos.
- **`flake.lock`:** Mantén este archivo registrado en Git cuando la
  configuración esté en un estado estable, ya que `nix flake update` puede
  introducir cambios procedentes de los proyectos originales.
