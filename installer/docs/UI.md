# Interfaz del instalador

## Estructura de la ventana

La ventana es un `FloatingWindow` transparente. Todo lo visible lo dibujan estas piezas, de fuera hacia dentro:

| Bloque | Archivo | Qué dibuja |
| --- | --- | --- |
| Barra lateral | `Installer.qml` (`id: side`) | Fondo `Pal.panel`, esquinas izquierdas redondeadas con `Pal.winRadius` |
| Contenido | `Installer.qml` (`id: main`) | Fondo `Pal.bg`, esquinas derechas redondeadas con `Pal.winRadius` |
| Diálogo de contraseña | `Installer.qml` (`id: pwDialog`) | Velo oscuro sobre el contenido, con las mismas esquinas derechas |
| Capa superior | `Installer.qml` (`id: overlay`) | Menús desplegables sobre todo lo demás |

La barra lateral y el contenido están uno al lado del otro y no se superponen. Así, con opacidad menor a 100 %, cada zona tiene exactamente la opacidad elegida y no una suma de dos capas.

## Por qué aparecían esquinas fantasma

- La ventana dibujaba un único rectángulo cuadrado. El compositor redondea las esquinas por su lado, así que ambas formas no coincidían y se veían restos en las esquinas, sobre todo con transparencia o blur.
- En la vista Terminal de Cambios, `clip: true` no recorta con el radio de las esquinas. La barra de título, que es cuadrada, sobresalía por encima del borde redondeado.
- La barra lateral y el contenido se superponían sobre un fondo común. Con transparencia, la zona de la barra se veía más opaca que el resto.
- El ancho animado de la barra lateral podía dejar una línea de un píxel sin dibujar entre barra y contenido.

## Cómo se corrigió

- La ventana usa radios por esquina (`topLeftRadius`, `topRightRadius`, `bottomLeftRadius`, `bottomRightRadius`) para que cada zona siga la forma de la ventana. Requiere Qt 6.7 o superior.
- La vista Terminal de Cambios ya no tiene barra de título propia.
- El ancho de la barra lateral se redondea a píxeles enteros.

## Radio de la ventana (Ajustes, Ctrl+4)

| Valor | Resultado |
| --- | --- |
| 0 (auto) | La app dibuja esquinas cuadradas y deja que el compositor las redondee |
| 1 a 32 px | La app redondea sus propias esquinas con ese radio |

Si el radio de la app es mayor que el del compositor, quedan huecos en las esquinas. Si ves esquinas fantasma, usa el mismo valor que tu compositor:

| Compositor | Opción |
| --- | --- |
| Hyprland | `decoration:rounding` |
| niri | `geometry-corner-radius` |
| MangoWM | `border_radius` |

Se guarda como `windowRadius` en `~/.config/nix-home-installer/settings.json`.

## Reglas para mantener las esquinas limpias

- Todo hijo que llene un contenedor con `radius` y `clip: true` debe usar radios por esquina; `clip` no respeta el radio.
- No pongas un fondo con transparencia debajo de otro fondo con transparencia en la misma zona.
- Las capas que cubren el contenido (velos, diálogos) deben heredar `Pal.winRadius` en las esquinas exteriores.

## Pestañas

| Atajo | Pestaña | Contenido |
| --- | --- | --- |
| Ctrl+1 | Paquetes | Buscar, probar y añadir |
| Ctrl+2 | Cambios | Pasos, modo de aplicación, Resumen, Diff y Terminal (salida en vivo y comandos manuales) |
| Ctrl+3 | Editor | Archivos `.nix` |
| Ctrl+4 | Ajustes | Apariencia y carpeta de configuración |

La antigua pestaña Terminal se fusionó en Cambios: había dos pantallas con los mismos botones y la misma salida, y no quedaba claro cuál usar para instalar. Toda ejecución (validar, aplicar, probar, comandos manuales) comparte un único `Runner` y se muestra en la vista Terminal de Cambios; `showOutput()` en `Installer.qml` la abre desde cualquier lugar.
