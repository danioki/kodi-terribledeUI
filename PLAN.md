# Plan: skin de Kodi inspirada en Apple TV

Nombre de trabajo: **Aura** (`skin.aura`).

Objetivo: dos pilares al mismo nivel.

1. **Home** — al abrir Kodi, **Novedades** primero y después las secciones de siempre (seguir viendo, películas, series…). Spec: [`docs/home-ux.md`](docs/home-ux.md).
2. **Player** — ver sin pelearte con Kodi (audio, subtítulos, seek, siguiente episodio). Spec: [`docs/player-ux.md`](docs/player-ux.md).

El look de salón no es un marco decorativo: es cómo se descubre el contenido. El player es cómo se ve.

Este documento es el plan de producto y arquitectura. No implementa la skin todavía.

---

## 1. Qué vamos a construir (y qué no)

Kodi no tiene “temas CSS”. La UI es un **addon de tipo skin**: XML + texturas PNG + fuentes + `addon.xml`. Cada pantalla de Kodi (Home, biblioteca, OSD, settings, PVR, diálogos…) es un archivo XML obligatorio. Si falta uno, Kodi cae a Estuary o se rompe.

Por eso **no se diseña una app nueva**. Se diseña una skin que Kodi puede cargar.

### Prioridad de producto

1. **Home** — Novedades primero, luego las secciones normales. Descubrir sin sidebar.
2. **Reproducción seamless** — OSD, audio, subtítulos, seek, siguiente episodio.
3. Ficha del título (Play / Info sin fricción).

Recortar settings, PVR chrome y temas. No recortar ni el feed de Inicio ni el player.

### Referencia visual: Apple TV *actual*

El Apple TV de 2015 (rejilla de iconos de apps) **no** es el que queremos. Skins como AppTV y tvOS-X copian esa generación. El tvOS moderno es un catálogo de streaming:

- Barra superior de pestañas (Watch Now / Library / Search), no un menú lateral gordo.
- Un **hero** grande arriba (fanart de lo enfocado en Novedades).
- Debajo, **Novedades** (recién añadido) y **después** las estanterías normales (seguir viendo, películas, series).
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

Dos firmas: **Inicio** (descubrir) y **Player** (ver). El resto puede quedar “Estuary oscuro” al principio.

### 5.0 Home (Novedades + secciones)

Detalle en [`docs/home-ux.md`](docs/home-ux.md).

Al arrancar, el feed de Inicio es un scroll vertical. **Novedades va primero.** Luego las secciones que uno espera en un salón:

| Orden | Sección | Rol |
| --- | --- | --- |
| 1 | **Novedades** — películas y episodios recién añadidos | Firma del home. Lockup landscape. Hero ligado al foco |
| 2 | **Seguir viendo** | In-progress, con barra |
| 3 | **Películas** | Estantería de posters (atajo; la pestaña abre la biblioteca) |
| 4 | **Series** | Igual |
| 5+ | Favoritos, Música, Directo, Addons | Solo si hay contenido |

Novedades en Kodi = `dateadded` (lo que acaba de entrar en la librería), no un editorial de tienda. No se duplica “recently added” más abajo.

Pestañas: Search · **Inicio** · Películas · Series. Inicio *es* el feed; no hay un tab aparte de Novedades.

Criterio de éxito: arrancar y ver Novedades sin buscar; abajo Seguir viendo y las bibliotecas; sin sidebar.

### 5.1 Player

Detalle en [`docs/player-ux.md`](docs/player-ux.md).

Dos capas:

- **Ver:** cromo inferior (título, restante, seek, skip ±10s, Audio, CC, Más). El vídeo no se pausa.
- **Elegir pista:** una hoja. Idioma primero, codec debajo. Off de subtítulos es un ítem. Un click aplica y cierra.
- **Ajustar (`···`):** delay, tamaño de subs, info de codec. Nunca para cambiar de idioma.

Estuary hoy manda al usuario a `osdaudiosettings` / `osdsubtitlesettings` / `CycleSubtitle`. Eso se sustituye. En Piers, los botones Audio y CC abren `DialogSelectAudio` y `DialogSelectSubtitle` skineados como esa hoja.

Criterio de éxito: MKV con 2 audios y 3 subs → cambiar idioma y CC en un click cada uno, sin entrar en Settings.

### 5.2 Biblioteca (Movies / TV)

Vista por defecto: **poster wall** con el mismo lockup que Home (radio, zoom al foco, título debajo). Vista secundaria: lista ancha (backdrop + meta). Sin vista “shift” ni adornos de Estuary.

### 5.3 Ficha (DialogVideoInfo)

Página de título tipo Apple TV:

- Fanart a pantalla, gradiente a negro hacia abajo/izquierda.
- Título grande, año, duración, rating, géneros.
- Botones: Play, Trailer, Queue, más…
- Debajo: reparto en estantería horizontal, similar, extras.

### 5.4 Resto (fase posterior)

Settings, PVR, música, addons, teclado, selectores: recolor + tipografía + focus tokens. Layout Estuary recortado. No se rediseñan hasta que Inicio y el player se sientan bien.

---

## 6. Arquitectura del addon

```
skin.aura/
  addon.xml                 # id, xbmc.gui version, res 1920x1080
  xml/
    Home.xml                # Inicio: Novedades primero, luego secciones
    Includes_Home.xml
    VideoOSD.xml            # cromo de reproducción
    DialogSeekBar.xml       # barra + tiempos, alineado al OSD
    DialogSelect.xml        # hojas de audio / subs / vídeo (Piers)
    Custom_1102_PlayerStreams.xml  # opcional, dos columnas
    DialogSubtitles.xml     # descargar SRT, mismo look
    DialogPlayerProcessInfo.xml
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

Dependencias del MVP: `xbmc.gui` **≥ 5.16** (carga en Nexus/Omega para probar Home). Las hojas nativas `DialogSelectAudio` / `DialogSelectSubtitle` requieren **Piers (5.18+)**. Sin Skin Shortcuts ni TMDbHelper.

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

### Fase 2 — Home (Novedades + secciones)

- Quitar el sidebar de Estuary.
- Pestañas Search · Inicio · Películas · Series.
- Hero ligado al foco.
- Bloque **Novedades** primero (películas + episodios recently added, lockup landscape).
- Después: Seguir viendo, Películas, Series; el resto solo si hay contenido.
- Empty states; no duplicar recently added.

**Criterio de éxito:** la demo de [`docs/home-ux.md`](docs/home-ux.md).

### Fase 3 — Player

- `VideoOSD.xml`: 5 acciones, título, restante. Sin iconos de más.
- `DialogSeekBar.xml` alineado al OSD (una sola pieza visual).
- Hojas `DialogSelectAudio` / `DialogSelectSubtitle`: idioma primero, Off en subs, un click.
- Botón CC y Audio en el OSD con **label del estado actual** (`ES 5.1`, `CC Off`).
- `···` para delay / info; no para elegir pista.
- Keymap: OK abre OSD, abajo abre pistas, skip ±10s.
- Series: `Siguiente episodio` si hay next.

**Criterio de éxito:** la demo de [`docs/player-ux.md`](docs/player-ux.md) (2 audios, 3 subs, un click cada cambio, el vídeo no se pausa).

### Fase 4 — Ficha del título

- DialogVideoInfo: Play evidente, meta clara, que no añada fricción antes del player.

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
| El OSD sigue oliendo a Estuary (settings, cycle) | Demo de pistas es gate de la fase Player |
| Inicio sigue siendo sidebar + widgets | Novedades primero es gate de la fase Home |
| Recently added duplicado más abajo | Un solo bloque Novedades; las estanterías de Películas/Series son catálogo |
| DialogSelect de Piers no admite dos columnas | Plan A: dos hojas gemelas; Plan B: custom window |
| OSD + SeekBar se desalinean | Includes compartidos, mismas coordenadas Y |
| Zoom de foco recorta posters / landscapes | padding en wraplists |
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

Checklist de Inicio (obligatoria): arranca en Novedades, hero sigue al foco, Seguir viendo debajo, Películas/Series después, sin sidebar ni recently added duplicado.

Checklist del player (obligatoria): OSD no pausa, Audio/CC muestran idioma actual, cambiar pista es un click, Back limpia la pantalla, skip 10s, siguiente episodio en series.

Checklist del resto (después): foco visible, sin callejones, back vuelve a Inicio.

---

## 10. Decisiones tomadas (para no bloquear)

1. **Producto:** skin Kodi. Dos pilares: Inicio (Novedades + secciones) y player seamless.
2. **Home:** Novedades primero (`dateadded`); después Seguir viendo, Películas, Series; el resto si hay contenido.
3. **Player:** hoja de pistas (idioma primero), no CycleSubtitle ni settings de audio para cambiar de lengua.
4. **Look:** tvOS moderno (shelves + hero + tabs), no icon grid ATV3.
5. **Base:** fork de Estuary Piers.
6. **Nombre de trabajo:** Aura.
7. **Target:** Kodi 22 Piers, 1080p.
8. **Idioma de UI:** español + inglés.
9. **Dependencias extra:** ninguna en el MVP.

---

## 11. Siguiente paso de implementación

Cuando se pase de plan a código:

1. Vendor de Estuary Piers → `skin.aura/`.
2. `Home.xml`: Novedades primero, luego secciones normales.
3. `VideoOSD.xml` + hojas de audio/subs.
4. Demos de `docs/home-ux.md` y `docs/player-ux.md`.
5. Después: ficha y biblioteca.

Hasta entonces, `PLAN.md`, `docs/home-ux.md`, `docs/player-ux.md` y `docs/design-system.md` son la fuente de verdad.
