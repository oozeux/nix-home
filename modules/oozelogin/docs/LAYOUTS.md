# OozeLogin: estilos de pantalla

Este documento explica cómo está organizada la pantalla de inicio de sesión, qué hace cada bloque y cómo añadir un estilo nuevo. El código QML no lleva comentarios; la explicación vive aquí.

## Estilos disponibles

| Valor de `layoutStyle` | Nombre | Descripción |
|---|---|---|
| `single` (por defecto) | Tarjeta única | Una tarjeta de cristal centrada. El avatar sobresale por arriba. Contiene nombre, reloj, contraseña, estado y controles. |
| `split` | Dashboard | Reloj a la izquierda, divisor vertical, tarjeta de acceso y panel lateral con sesión, teclado, reiniciar y apagar. |
| `ambient` | Minimalista | Sin tarjeta. Reloj grande, avatar, nombre y contraseña sobre el fondo. Luna, reiniciar y apagar arriba a la derecha; sesión y teclado abajo a la derecha. |
| `classic` | Clásico | El diseño anterior: panel de información a la izquierda, panel de sesión a la derecha y acceso al centro. |

Se cambia desde **Ajustes > Interfaz > Estilo de pantalla** o con `services.oozelogin.settings.layoutStyle = "split";` en Nix. Un valor desconocido cae a `single`.

## Estructura de carpetas

```
qml/
  shell.qml            Ventanas del greeter (una por pantalla) y ventana de vista previa
  settings.qml         Ventana de ajustes
  Core/                Estado compartido (singletons)
  Layouts/             Un archivo por estilo de pantalla
  Ui/                  Componentes reutilizables
  Settings/            Páginas y controles de la ventana de ajustes
```

## Core (singletons)

| Archivo | Responsabilidad |
|---|---|
| `Config.qml` | Lee y guarda la configuración. Valores por defecto en `defaults`. `Config.v` es la configuración final; `Config.weatherWanted` indica si hay que consultar el clima según el estilo activo. |
| `Auth.qml` | Conversación con greetd. Expone `username`, `shownName`, `avatarSource`, `sessionId`, estado de error y `submit()`. |
| `Sys.qml` | Usuarios, sesiones, distribución de teclado (`setLayout`, `cycleLayout`), clima, estadísticas y acciones de energía (`reboot`, `poweroff`, `suspend`). |
| `Strings.qml` | Textos en español e inglés, fechas y hora. |
| `Glyph.qml` | Códigos de iconos Nerd Font. |

## Escena y contrato de los layouts

`Ui/Scene.qml` dibuja el fondo (`Backdrop`), captura clics en espacio vacío y carga con un `Loader` el layout elegido.

Todo archivo de `Layouts/` debe ofrecer esta interfaz:

| Miembro | Tipo | Uso |
|---|---|---|
| `u` | `real` | Factor de escala. Todas las medidas se multiplican por él. |
| `backdrop` | `Item` | Fondo que `Glass` usa para el desenfoque. |
| `menu` | `string` | Menú desplegable abierto (`""`, `"session"` o `"language"`). |
| `focusInput()` | función | Devuelve el foco al campo de contraseña. |
| `dismiss()` | función | Cierra menús abiertos. La escena lo llama al hacer clic fuera. |

### Reglas importantes

- Un `Glass` debe ser hijo directo del layout. Calcula la zona de fondo a desenfocar con su `x` e `y`, que deben estar en el mismo sistema de coordenadas que el fondo.
- El contenido de un `Glass` se coloca dentro de él (por ejemplo con un `ColumnLayout`).
- Para que un menú abierto quede por encima, el contenedor correspondiente sube su `z` a 100 mientras `menu !== ""`. El avatar de `SingleCardLayout` usa `card.z + 1` para no quedar tapado.

## Qué contiene cada layout

**SingleCardLayout**: destellos de fondo, barra superior plana, tarjeta `Glass` (nombre, `ClockBlock`, `PasswordField`, `StatusLine`, `ControlBar`, `UserChips`), `AvatarHalo` montado sobre el borde superior, barra de controles opcional debajo, frase inferior y puntos de fondo. Opción `singleToolbar`: `inside` (dentro de la tarjeta) o `below` (en una pastilla debajo).

**SplitLayout**: `ClockBlock`, divisor degradado, tarjeta de acceso y panel lateral con `SessionDrop`, `LanguageDrop` y dos `PowerButton` en modo fila. El conjunto se centra y se ajusta si falta el reloj o el panel.

**AmbientLayout**: `ClockBlock` con sombra, avatar, nombre en `Pill`, campo de contraseña, estado, tres `PowerButton` circulares arriba a la derecha y un `ControlBar` sin energía abajo a la derecha.

**ClassicLayout**: el `Scene` anterior movido tal cual: `TopBar`, `InfoPanel`, `SidePanel`, `AuthBlock`, `Tagline`, marca inferior y `Dots`.

## Componentes de Ui añadidos

| Componente | Función |
|---|---|
| `Sparkle` | Estrella de cuatro puntas dibujada con `Shape`. |
| `Sparkles` | Campo de estrellas con parpadeo suave. Se activa con `sparkles`. |
| `SparkleDivider` | Línea con estrella central. |
| `ClockBlock` | Hora, fecha, clima en línea y divisor. Propiedades `timeSize`, `dateSize`, `shadow`, `divider`. |
| `PasswordField` | Campo de contraseña con sacudida de error, ojo y aviso de bloqueo de mayúsculas. |
| `StatusLine` | Mensaje de estado, error o vista previa. |
| `UserChips` | Lista de usuarios cuando hay más de uno. |
| `AvatarHalo` | Avatar con anillo exterior y destellos. |
| `DropPill` | Pastilla desplegable genérica. `up` abre hacia arriba, `block` ocupa todo el ancho, `popupAlign` alinea el menú. |
| `SessionDrop` | Selector de sesión. |
| `LanguageDrop` | Selector de teclado e idioma de la interfaz. |
| `PowerButton` | Reiniciar, apagar o suspender. Pide confirmación con un segundo clic en 3 segundos. En vista previa no ejecuta nada. |
| `ControlBar` | Fila con sesión, teclado y botones de energía. |

`AuthBlock`, `TopBar` y `Scene` se modificaron: `AuthBlock` ahora usa `PasswordField`, `StatusLine` y `UserChips`; `TopBar` acepta `flat` y `showRight`.

## Qué opción afecta a qué estilo

| Opción | Estilos |
|---|---|
| `showTopBar`, `showTagline`, `showDots`, `showUsers`, `labelBubbles` | Todos |
| `showClock`, `showWeather`, `clock24h` | Todos (en Clásico, `showClock` y `showWeather` viven en el panel de información) |
| `showSessionPanel` | Todos (selector de sesión) |
| `showKeyboard` | Todos (selector de teclado e idioma) |
| `showPower` | Todos |
| `showInfoPanel`, `showStats`, `showFooter`, `sessionPanelExpanded` | Solo Clásico |
| `singleToolbar` | Solo Tarjeta única |
| `sparkles` | Todos menos Clásico |

## Cómo añadir un estilo nuevo

1. Crea `Layouts/MiLayout.qml` con la interfaz del contrato.
2. Añade un `Component` para él en `Ui/Scene.qml` y una condición en el `sourceComponent` del `Loader`.
3. Añade el valor en el `Choice` de `Settings/InterfacePage.qml` y el texto `layoutMiEstilo` en ambos idiomas de `Core/Strings.qml`.
4. Reutiliza los componentes de `Ui/` en lugar de copiar código.
5. Pruébalo con `oozelogin-preview`.

## Permisos

El botón de suspender usa `systemctl suspend`. La regla polkit del usuario `greeter` en `default.nix` ahora incluye `org.freedesktop.login1.suspend`.
