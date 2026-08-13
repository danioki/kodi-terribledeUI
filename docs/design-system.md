# Aura — sistema de diseño

Inspirado en tvOS actual. No es una copia de Human Interface Guidelines de Apple; es un set de tokens para XML de Kodi a 1920×1080.

## Principios

1. **Un foco.** El ítem activo es más grande, más claro y tiene título. El resto no compite.
2. **10 pies.** Títulos ≥ 28 px efectivos. No depender de texto de 12 px.
3. **Aire.** Márgenes laterales ~80–100 px. Estanterías no pegadas al borde.
4. **Oscuro de verdad.** Fondo negro, no gris azulado de Estuary.
5. **Artwork manda.** El poster *es* el botón. Iconos de chrome, mínimos.
6. **El vídeo manda más.** Durante playback, el cromo es inferior, transitorio y nunca tapa el centro. Audio y CC son acciones de primer nivel, no settings.

## Color

| Rol | Hex | Uso |
| --- | --- | --- |
| `bg` | `#000000` | Canvas |
| `bg.elevated` | `#0B0B0D` | Diálogos, OSD |
| `text.primary` | `#EBEBF5` (92% blanco) | Títulos |
| `text.secondary` | `#EBEBF599` (60%) | Meta, relojes, labels de shelf |
| `text.tertiary` | `#EBEBF54D` (30%) | Hints, disabled |
| `separator` | `#FFFFFF1A` | Líneas, si hace falta |
| `focus.glow` | sombra negra, no halo de color | Lockup enfocado |
| `accent` | `#FFFFFF` | Tabs activas, progress |
| `accent.optional` | `#7AA2FF` | Ratings / PVR, nunca el único indicador de foco |

Kodi: `colors/defaults.xml` + `$VAR[…]` / `Includes_Colors.xml`.

## Tipografía

No empaquetar San Francisco (licencia Apple). Candidatas open:

- **Manrope** o **Outfit** para UI (geométrica, TV).
- **Inter** si hace falta más pesos.

Escala 1080p (aprox.):

| Estilo | px | Peso | Uso |
| --- | --- | --- | --- |
| Hero title | 56–72 | Semibold | Título sobre fanart |
| Shelf header | 28–32 | Semibold | “Continue Watching” |
| Lockup title | 22–24 | Medium | Solo en foco (o siempre, si cabe) |
| Tab | 26–28 | Medium / Semibold si activa | Barra superior |
| Body / meta | 22 | Regular | Año, duración |
| Clock | 24 | Regular | Esquina |
| OSD title | 32 | Semibold | Título sobre el vídeo |
| OSD meta | 22 | Regular | Restante, idioma actual |
| Stream row | 28 / 22 | Semibold / Regular | Idioma / codec en la hoja |

Tracking amplio en tabs. Evitar ALL CAPS de Estuary.

## Layout 1920×1080

```
safe-x:        96 px
tab-bar-y:     36–96  (altura ~60)
hero-y:        110–520  (~410 alto, 16:9 recortado)
shelf-gap:     36–48
poster:        220 × 330  (2:3)
landscape:     360 × 202  (16:9, continue watching)
focus-scale:   1.10
focus-pad:     24 extra alrededor del wraplist para que el zoom no recorte
```

5 posters de 220 + gaps de 24 ≈ 1220; con peek del 6º ítem a la derecha.

## Lockup (componente clave)

Estado idle:

- Poster con máscara rounded (~16 px).
- Sin borde. Sin título, o título al 40% de opacidad.

Estado focused:

- Zoom 1.10, 150–200 ms, easing out.
- Sombra PNG debajo (no glow azul).
- Título + año aparecen debajo (fade 100 ms).
- Progress bar fina en Continue Watching.

Implementación Kodi:

- `<texture border="16">` o overlay de máscara.
- `<animation effect="zoom" start="100" end="110" time="180" reversible="true" condition="Control.HasFocus(id)">`
- Label con `visible="Control.HasFocus(id)"`.

No hay parallax. No hay specular. El zoom *es* el foco.

## Hero

- Fanart a casi todo el ancho, recorte 16:9, viñeta a negro abajo.
- Clearlogo si existe (`ListItem.Art(clearlogo)`), si no el título.
- Dos botones: Play, Info. Foco por defecto en Play cuando el hero está activo.
- Alternativa MVP: el hero es *display* del ítem enfocado en la primera estantería (no es un control aparte). Más simple de navegar.

## Tabs

Fila horizontal, no sidebar.

- Inactiva: `text.secondary`.
- Activa: `text.primary` + subrayado blanco de 2 px, o peso semibold. No pastilla azul.
- Search a la izquierda (icono lupa discreto). Clock a la derecha.

## Motion

| Evento | Duración |
| --- | --- |
| Focus zoom | 180 ms |
| Title fade | 100 ms |
| Shelf scroll | `scrolltime` 200–300 |
| Window fade | 200 ms |
| Hero crossfade | 400 ms |

Sin rebotes. Sin slides laterales de ventana tipo Estuary si se puede evitar (dan sensación “Kodi 2016”).

## Player chrome

Layout 1080p del overlay (detalle de interacción en `docs/player-ux.md`):

```
safe-x:          96
osd-bottom:      0–280  (gradiente negro → transparente hacia arriba)
seekbar-y:       ~920
actions-y:       ~980
stream-sheet:    bottom 52% or right 42%; nunca un modal centrado
```

- Acciones OSD: icono 48 + label 22. Audio y CC **llevan texto de estado** (`ES 5.1`, `Off`), no solo el pictograma.
- Hoja de pistas: fila 72 px, tick a la izquierda, dos líneas. Columna activa con foco claro.
- El seek no usa el slider gordo de Estuary; línea de 4 px, knob 16 al foco.

## Iconografía

Línea fina, 2 px, estilo SF Symbols *en espíritu* — set propio o Material Symbols / Lucide rasterizados a PNG. Nunca el logo de Apple ni iconos de apps de tvOS.

## Sonido

Opcional. tvOS usa ticks de foco. Kodi: `resource.uisounds.*`. Fuera del MVP; el silencio es mejor que un pack genérico.

## Accesibilidad 10'

- Contraste texto primario sobre negro ≥ 7:1.
- Foco nunca solo por color.
- Hit area del lockup = poster completo, no el label.
- Reloj y estado de player visibles sin quitar el mando del sofá.

## Anti-patrones (skins actuales)

- Sidebar permanente + widgets a la derecha (Estuary).
- Grid de iconos de “apps” (AppTV / tvOS-X).
- Poster con borde arcoíris + overlay de info densa.
- Vista wall con 20 posters minúsculos.
- Tipografía condensada y labels en mayúsculas.
- OSD con 12 botones de codec/settings.
- Cambiar de idioma vía `CycleSubtitle` o `osdaudiosettings`.
- Panel que cubre caras / pausa el vídeo al abrir pistas.
