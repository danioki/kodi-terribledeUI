# Plan: skin de Kodi inspirada en Apple TV

Nombre de trabajo: **Aura** (`skin.aura`).

Objetivo principal: **ver una película o una serie sin pelearte con Kodi**. Cambiar subtítulos, cambiar audio, saltar 10 segundos y pasar al siguiente capítulo tiene que ser tan directo como en un reproductor moderno (Apple TV / Disney+). El look de salón (pestañas, hero, estanterías) es el marco; el producto es el player.

Spec de reproducción: [`docs/player-ux.md`](docs/player-ux.md).

Este documento es el plan de producto y arquitectura. No implementa la skin todavía.

---

## 1. Qué vamos a construir (y qué no)

Kodi no tiene “temas CSS”. La UI es un **addon de tipo skin**: XML + texturas PNG + fuentes + `addon.xml`. Cada pantalla de Kodi (Home, biblioteca, OSD, settings, PVR, diálogos…) es un archivo XML obligatorio. Si falta uno, Kodi cae a Estuary o se rompe.

Por eso **no se diseña una app nueva**. Se diseña una skin que Kodi puede cargar.

### Prioridad de producto

1. **Reproducción seamless** — OSD, audio, subtítulos, seek, siguiente episodio.
2. Ficha del título (Play sin fricción).
3. Home / biblioteca al estilo tvOS (descubrimiento).

Si hay que recortar, se recorta el home, no el player.

### Referencia visual: Apple TV *actual*

El Apple TV de 2015 (rejilla de iconos de apps) **no** es el que queremos. Skins como AppTV y tvOS-X copian esa generación. El tvOS moderno es un catálogo de streaming:

- Barra superior de pestañas (Watch Now / Library / Search), no un menú lateral gordo.
- Un **hero** grande arriba (artwork de lo destacado o en curso).
- Debajo, **estanterías horizontales** (Continue Watching, Recently Added, Movies, Shows).
- Posters con esquinas redondeadas.
- El foco **escala**, levanta sombra y muestra el título; el resto se queda quieto.
- Fondo casi negro, tipografía grande, poco cromo, mucho espacio.
- Mando / D-pad como input principal. El ratón es secundario.
- Durante el vídeo: cromo mínimo, hoja única de Audio + subtítulos, no un árbol de settings.

### Qué no vamos a copiar

- Logotipos, iconos, SF Pro, ni el nombre “Apple TV”.
- Parallax 3D y brillo especular del foco de tvOS (el motor de Kodi no lo tiene).
- Blur de cristal en tiempo real (se puede *simular* con overlays).

Inspiración de interacción y layout. Identidad propia.

---

## 2. Por qué no partir de cero

Una skin completa de Kodi tiene del orden de **80–100 ventanas XML** (Home, MyVideoNav, DialogVideoInfo, DialogSeekBar, Settings, PVR, teclado, selectores, addons…). Escribirlas todas es reimplementar Kodi.

| Opción | Pros | Contras | Decisión |
| --- | --- | --- | --- |
| Skin desde cero | Libertad total | Meses en diálogos/settings; fácil dejar huecos | Descartada para el MVP |
| Fork de AppTV / tvOS-X | Ya “parece Apple” | Imitan ATV antiguo; código viejo; poco mantenimiento | Descartada |
| Fork de Arctic Horizon 2 | Widgets potentes, look moderno | Compleja, Skin Shortcuts + TMDbHelper | Más adelante, si hace falta |
| **Fork de Estuary (Piers / Kodi 22)** | Completa; Piers trae `DialogSelectAudio` / `DialogSelectSubtitle` | Hay que destrozar OSD y home de Estuary | **Base del MVP** |

Estuary cubre todas las ventanas. Piers es el target porque por fin el motor **lista las pistas** (idioma, tick de activa, Off de subs) en diálogos que la skin puede pintar. En Omega 21 solo hay `CycleSubtitle` y settings: no da para una hoja moderna.

El trabajo de producto no es inventar el data binding de la librería. Es **sacar audio/subs de los settings y ponerlos en el cromo de ver**.

Licencia: Estuary es CC BY-SA 4.0 / GPL-2.0. Aura debe atribuir y compartir bajo licencia compatible.

---

## 3. Límites del motor de Kodi (expectativas)

El skinning engine no es SwiftUI. Esto sí se puede:

- `wraplist` / `panel` horizontales = estanterías.
- Animaciones de foco: `<animation effect="zoom">`, fade, slide.
- Esquinas redondeadas vía texturas (máscaras PNG).
- Widgets de librería sin Python extra.
- Navegación D-pad explícita (`onup` / `ondown` / `onleft` / `onright`).
- Piers: `ActivateWindow(DialogSelectAudio|Subtitle)` con listas reales de pistas.
- Acciones de player: `ShowSubtitles`, `Seek()`, `PlayerControl(Play)`, delay de audio/subs.

Esto no (o muy a medias):

- Parallax / tilt al mover el trackpad.
- Gaussian blur vivo del fanart (se finge con imagen oscurecida + viñeta).
- Tipografía variable y tracking fino de SF Pro.
- Layout fluido tipo `containerRelativeFrame` (todo es coordenadas 1920×1080).
- Un único control nativo “Audio + Subs en dos columnas” (se finge con dos diálogos o un custom window).
- Skip intro automático sin chapters / addon.

Diseñar *dentro* de esas reglas, no pelear contra ellas.

---

## 4. Sistema de diseño (resumen)

Detalle en [`docs/design-system.md`](docs/design-system.md).

| Token | Valor de trabajo |
| --- | --- |
| Canvas | 1920×1080, aspect 16:9 |
| Fondo | `#000000` / `#0B0B0D` |
| Texto | Blanco 92% / gris 60% para secundario |
| Acento | Blanco; un acento frío opcional `#7AA2FF` (no el azul iOS clásico) |
| Radio posters | ~12–16 px (máscara) |
| Foco | Zoom ~1.08–1.12 + sombra + título visible |
| Tipografía | Fuente sans geométrica open (Inter / Manrope / Outfit), no SF Pro |
| Densidad | 5–6 posters por estantería; 1 hero; 2–3 estanterías visibles |

Principio: **un solo foco inequívoco**. Nada de bordes de color + glow + underline a la vez.

---

## 5. Pantallas que definen el producto

El 80% de la percepción es **el player**. Home + biblioteca + ficha solo sirven para llegar a Play. El resto puede quedar “Estuary oscuro” al principio.

### 5.0 Player (la firma)

Detalle en [`docs/player-ux.md`](docs/player-ux.md).

Dos capas:

- **Ver:** cromo inferior (título, restante, seek, skip ±10s, Audio, CC, Más). El vídeo no se pausa.
- **Elegir pista:** una hoja. Idioma primero, codec debajo. Off de subtítulos es un ítem. Un click aplica y cierra.
- **Ajustar (`···`):** delay, tamaño de subs, info de codec. Nunca para cambiar de idioma.

Estuary hoy manda al usuario a `osdaudiosettings` / `osdsubtitlesettings` / `CycleSubtitle`. Eso se sustituye. En Piers, los botones Audio y CC abren `DialogSelectAudio` y `DialogSelectSubtitle` skineados como esa hoja.

Criterio de éxito: MKV con 2 audios y 3 subs → cambiar idioma y CC en un click cada uno, sin entrar en Settings.

### 5.1 Home (la firma)

```
┌─────────────────────────────────────────────────────────┐
  Search    Watch Now    Movies    TV    Library    [clock]
├─────────────────────────────────────────────────────────┤
│                                                         │
│   HERO  16:9  (fanart + logo + Play / More info)        │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  Continue Watching                                      │
│  [■■] [■■] [■■] [■■] [■■] →                             │
│  Recently Added Movies                                  │
│  [█] [█] [█] [█] [█] [█] →                              │
│  Recently Added TV Shows                                │
│  [█] [█] [█] [█] [█] [█] →                              │
└─────────────────────────────────────────────────────────┘
```

Comportamiento:

1. Arriba: pestañas (grouplist horizontal). Foco inicial en **Watch Now**.
2. Watch Now no “cambia de categoría Estuary”; es un **scroll vertical de estanterías**.
3. Arriba/abajo cambia de estantería; izquierda/derecha recorre ítems.
4. El hero refleja el ítem enfocado (fanart + título) *o* un destacado fijo. Decisión de MVP: **hero ligado al foco** (más Apple TV / Netflix living room).
5. Movies / TV / Library abren las ventanas nativas, no otra home distinta.
6. Search abre `DialogSearch` / ventana de búsqueda.

Widgets por defecto (si hay librería):

| Estantería | Fuente Kodi |
| --- | --- |
| Continue Watching | `videodb://inprogresstvshows` + in-progress movies |
| Recently Added Movies | `videodb://recentlyaddedmovies` |
| Recently Added TV | `videodb://recentlyaddedepisodes` |
| Movies | `videodb://movies/titles/` |
| TV Shows | `videodb://tvshows/titles/` |
| Unwatched | playlist `.xsp` |

Sin librería: empty state limpio (“Add media sources”) en vez del wall de iconos de Estuary.

### 5.2 Biblioteca (Movies / TV)

Vista por defecto: **poster wall** con el mismo lockup que Home (radio, zoom al foco, título debajo). Vista secundaria: lista ancha (backdrop + meta). Sin vista “shift” ni adornos de Estuary.

### 5.3 Ficha (DialogVideoInfo)

Página de título tipo Apple TV:

- Fanart a pantalla, gradiente a negro hacia abajo/izquierda.
- Título grande, año, duración, rating, géneros.
- Botones: Play, Trailer, Queue, más…
- Debajo: reparto en estantería horizontal, similar, extras.

### 5.4 Resto (fase posterior)

Settings, PVR, música, addons, teclado, selectores: recolor + tipografía + focus tokens. Layout Estuary recortado. No se rediseñan hasta que el player se sienta bien.

---

## 6. Arquitectura del addon

```
skin.aura/
  addon.xml                 # id, xbmc.gui version, res 1920x1080
  xml/
    VideoOSD.xml            # cromo de reproducción (prioridad)
    DialogSeekBar.xml       # barra + tiempos, alineado al OSD
    DialogSelect.xml        # hojas de audio / subs / vídeo (Piers)
    Custom_1102_PlayerStreams.xml  # opcional, dos columnas
    DialogSubtitles.xml     # descargar SRT, mismo look
    DialogPlayerProcessInfo.xml
    Home.xml                # pestañas + hero + shelves (después)
    Includes_Colors.xml / Includes_Focus.xml / Includes_Lockups.xml
    DialogVideoInfo.xml
    MyVideoNav.xml
    …resto copiado de Estuary y retocado
  media/                    # PNG, máscaras, sombras (Textures.xbt al empaquetar)
  fonts/
  colors/defaults.xml
  language/resource.language.en_gb|es_es/strings.po
  playlists/                # .xsp de widgets
  resources/                # icon, fanart, screenshots
```

Resolución de trabajo: **1920×1080**. Otras aspectos después, si hace falta.

Dependencias del MVP: `xbmc.gui` de **Piers (Kodi 22)**. Sin Skin Shortcuts, sin TMDbHelper, sin Up Next de terceros. El player usa APIs nativas de pistas.

Opcional más adelante: `script.skinshortcuts` para reordenar estanterías desde Settings.

---

## 7. Fases de trabajo

Cada fase termina en un zip instalable y una checklist de mando (arriba/abajo/ok/back).

### Fase 0 — Spec (este repo ahora)

- Plan y design system.
- Decisiones de naming, licencia, Kodi target.
- Inventario de ventanas Estuary que se tocan vs se heredan.

### Fase 1 — Scaffold

- Copiar Estuary **Piers**.
- Renombrar a `skin.aura`.
- Paleta oscura + fuente + tokens.
- Confirmar que arranca y que se puede reproducir un vídeo.

### Fase 2 — Player (prioridad máxima)

- `VideoOSD.xml`: 5 acciones, título, restante. Sin iconos de más.
- `DialogSeekBar.xml` alineado al OSD (una sola pieza visual).
- Hojas `DialogSelectAudio` / `DialogSelectSubtitle`: idioma primero, Off en subs, un click.
- Botón CC y Audio en el OSD con **label del estado actual** (`ES 5.1`, `CC Off`).
- `···` para delay / info; no para elegir pista.
- Keymap: OK abre OSD, abajo abre pistas, skip ±10s.
- Series: `Siguiente episodio` si hay next.

**Criterio de éxito:** la demo de [`docs/player-ux.md`](docs/player-ux.md) (2 audios, 3 subs, un click cada cambio, el vídeo no se pausa).

### Fase 3 — Ficha del título

- DialogVideoInfo: Play evidente, meta clara, que no añada fricción antes del player.

### Fase 4 — Home Aura

- Quitar sidebar de Estuary.
- Pestañas, hero, estanterías.
- Empty state.

### Fase 5 — Biblioteca + pulido

- Poster view, search, recolor de settings/PVR/música.
- Localización es/en, capturas, rendimiento ARM.

### Fuera de alcance del MVP

- Temas claro/oscuro múltiples.
- Personalización total tipo Arctic.
- Clone pixel-perfect de tvOS.
- Skip intro por IA / créditos automáticos sin chapters.
- Omega 21 como target del player (sin diálogos de pistas).
- Up Next / TMDbHelper como dependencia.
- Soporte táctil/tablet como prioridad.
- 4K nativo / ultrawide.

---

## 8. Riesgos

| Riesgo | Mitigación |
| --- | --- |
| El OSD sigue oliendo a Estuary (settings, cycle) | Fase 2 bloquea el resto; demo de pistas es el gate |
| DialogSelect de Piers no admite dos columnas | Plan A: dos hojas gemelas; Plan B: custom window |
| OSD + SeekBar se desalinean (dos ventanas Kodi) | Includes compartidos, mismas coordenadas Y |
| Abrir la hoja pausa o tapa caras | Panel inferior/lateral ~40% de alto; `Player.Paused` no se toca |
| Zoom de foco recorta posters (home, más tarde) | padding en wraplists |
| Marca Apple | Naming e iconografía propios |
| Scope creep (PVR, karaoke, games…) | Estuary heredado hasta Fase 5 |

---

## 9. Cómo se prueba

Kodi en esta VM de desarrollo no es el entorno real. El loop previsto:

1. Editar XML en el repo.
2. Empaquetar `skin.aura` (zip o carpeta en `addons/`).
3. Instalar / reload skin (`ReloadSkin()`).
4. Probar con teclado como D-pad (flechas, enter, backspace).
5. Más adelante: CoreELEC / Windows HTPC con mando real.

Checklist del player (obligatoria): OSD no pausa, Audio/CC muestran idioma actual, cambiar pista es un click, Back limpia la pantalla, skip 10s, siguiente episodio en series.

Checklist de menús (después): foco visible, sin callejones, back vuelve a Home.

---

## 10. Decisiones tomadas (para no bloquear)

1. **Producto:** skin Kodi. El core es el reproductor, no el launcher.
2. **Player:** hoja de pistas (idioma primero), no CycleSubtitle ni settings de audio para cambiar de lengua.
3. **Look de menús:** tvOS moderno (shelves + hero + tabs), no icon grid ATV3.
4. **Base:** fork de Estuary Piers.
5. **Nombre de trabajo:** Aura.
6. **Target:** Kodi 22 Piers, 1080p.
7. **Idioma de UI:** español + inglés.
8. **Dependencias extra:** ninguna en el MVP.

---

## 11. Siguiente paso de implementación

Cuando se pase de plan a código:

1. Vendor de Estuary Piers → `skin.aura/`.
2. Rehacer `VideoOSD.xml` + `DialogSeekBar.xml` + skins de `DialogSelectAudio/Subtitle`.
3. Demo con un MKV multi-pista (la checklist de `docs/player-ux.md`).
4. Después: ficha y Home.

Hasta entonces, `PLAN.md`, `docs/player-ux.md` y `docs/design-system.md` son la fuente de verdad.
