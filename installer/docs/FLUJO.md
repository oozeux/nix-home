# Flujo de instalación guiado

## Qué problema resuelve

Antes, la insignia «✔ en tu config» aparecía en cuanto el paquete se escribía en un archivo `.nix`, y parecía que ya estaba instalado. Ahora cada paquete muestra su estado real y el instalador guía el proceso completo sin obligar a abrir una terminal externa.

## Estados de un paquete

| Insignia | Significa |
| --- | --- |
| Sin aplicar | Está en tus archivos `.nix`, pero el sistema todavía no lo usa |
| Probado (temporal) | Activo hasta el próximo reinicio (`nixos-rebuild test`) |
| Se quitará | Lo quitaste de los archivos; sigue instalado hasta aplicar |
| En tu configuración | Está en los archivos y no hay cambios pendientes |

## Formas de usar un paquete

| Acción | Qué hace | Qué deja |
| --- | --- | --- |
| Probar sin instalar | Descarga el paquete y lo abre con `nix shell` | Nada: no toca tus archivos ni tu sistema |
| Probar sin guardar | `nixos-rebuild test` | Activo hasta reiniciar |
| Aplicar ahora | `nixos-rebuild switch` | Activo y permanente |
| Aplicar al próximo arranque | `nixos-rebuild boot` | Se activa al reiniciar; el sistema actual no cambia |

**Regla fija:** probar, aplicar y programar ejecutan siempre `dry-build` antes. Si falla, no se llama a `sudo` ni se cambia nada.

## Recorrido en la interfaz

1. **Paquetes**: buscar, elegir destino y pulsar *Probar sin instalar* o *Añadir a mi selección*.
2. **Tu selección** (barra inferior): muestra los cambios pendientes y permite quitarlos uno a uno.
3. **Cambios** (*Revisar y aplicar*): única pantalla para instalar. Estado paso a paso, elección del modo, resumen, diff y pestaña *Terminal* con la salida en vivo y una línea para comandos manuales.
4. Si se eligió *al próximo arranque*, aparece un aviso con el botón *Reiniciar ahora*.

## Cómo funciona por dentro

- El backend (`status`) devuelve `pending` (paquetes añadidos o quitados respecto al último estado aceptado), `fingerprint` (huella de los archivos cambiados) y `bootPending`.
- Los scripts de `Installer.qml` imprimen marcadores `##NH:validated`, `##NH:invalid` y `##NH:failed`. `Runner.qml` los oculta del log y avisa a la interfaz, que así sabe si falló la validación o la aplicación.
- La huella invalida la validación: si editas algo después de validar, el paso vuelve a pendiente.
- Solo `switch` y `boot` aceptan los cambios (borran los snapshots). `test` no, porque es temporal.

## Funciones que conviene vigilar

| Función | Archivo | Por qué |
| --- | --- | --- |
| `stepScript` | `Installer.qml` | Es el único sitio que garantiza la validación previa. Si añades un modo o una opción (`--upgrade`, `--impure`, builders remotos), conserva el `|| { …; exit 1; }` y mantén `sudo` después de la validación. |
| `tryPackage` | `Installer.qml` | Usa `nixosConfigurations.$HOST.pkgs`, igual que tu sistema (mismo nixpkgs y `allowUnfree`). Cambiarlo a `nixpkgs#` puede dar otra versión o fallar con paquetes unfree. Abre el binario `meta.mainProgram`; si falta, usa el nombre del atributo, que puede no coincidir. Está pensado para apps gráficas; para herramientas de terminal usa *Copiar nix shell*. Es buena candidata a modificar si quieres abrirlas dentro de un emulador de terminal. |
| `onRunFinished` | `Installer.qml` | Decide los mensajes y cuándo se acepta el cambio. Un modo nuevo debe decidir explícitamente si acepta; aceptar borra los snapshots y con ellos «Deshacer todo». |
| Detección de contraseña incorrecta | `Installer.qml` | Es una expresión regular sobre la salida de `sudo` y depende del idioma. Si tu sistema usa otro idioma, añade su mensaje; si no, una contraseña mala se seguirá reutilizando. |
| `activation_pending` | `main.rs` | Heurística: compara `/run/current-system` con el perfil `system`. Tras un `test` también da verdadero, por eso el aviso de reinicio solo se muestra sin cambios pendientes. Con specialisations o perfiles distintos puede dar falsos positivos. |
| `pending_changes` y `find_lists` | `main.rs` | Leen los archivos como texto, no evalúan Nix. Solo ven `home.packages` y `environment.systemPackages`; un paquete activado con `programs.x.enable` no aparece. Si tus archivos usan otra forma, es el lugar a ampliar. |
| `fingerprint` | `main.rs` | Hash FNV simple, solo para invalidar validaciones. No sirve como medida de seguridad. |

## Cambiar la carpeta de configuración

En **Ajustes → Carpeta de configuración** puedes escribir una ruta (acepta `~`), elegirla con ventana (necesita `zenity` o `kdialog`) o volver a *Automática*. La carpeta se valida antes de guardarla: si no tiene `flake.nix` y `configuration.nix`, se mantiene la anterior. Se recuerda en `settings.json` como `repoPath`.

| Función | Archivo | Por qué vigilarla |
| --- | --- | --- |
| `setRepo` | `Installer.qml` | Reinicia el estado de validación al cambiar. Se bloquea mientras corre un comando para no mezclar carpetas. Si abres el instalador con una ruta guardada que ya no existe, mostrará el error y podrás corregirla desde Ajustes. |
| `find_repo` | `main.rs` | Sube por los directorios padre hasta encontrar ambos archivos; si tu repo usa otro nombre que `configuration.nix`, es aquí donde hay que cambiarlo. |

## Limitaciones

- El estado «validado» y «probado» vive en memoria: si cierras el instalador se pierde. No es un riesgo, porque antes de aplicar siempre se valida de nuevo.
- Solo hay un lugar para aplicar cambios (pestaña Cambios); siempre valida primero con `dry-build`.
