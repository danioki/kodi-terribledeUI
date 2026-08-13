# Plan: skin de Kodi inspirada en Apple TV

Nombre de trabajo: **Aura** (`skin.aura`).
Objetivo: una interfaz de 10 pies, oscura, con mucho aire y foco claro, que se sienta como el Apple TV actual (tvOS 17/18), no como Estuary ni como las clones de Apple TV 2/3/4.

Este documento es el plan de producto y arquitectura. No implementa la skin todavía.

---

## 1. Qué vamos a construir (y qué no)

Kodi no tiene “temas CSS”. La UI es un **addon de tipo skin**: XML + texturas PNG + fuentes + `addon.xml`. Cada pantalla de Kodi (Home, biblioteca, OSD, settings, PVR, diálogos…) es un archivo XML obligatorio. Si falta uno, Kodi cae a Estuary o se rompe.

Por eso **no se diseña una app nueva**. Se diseña una skin que Kodi puede cargar.

### Referencia visual: Apple TV *actual*

El Apple TV de 2015 (rejilla de iconos de apps) **no** es el que queremos. Skins como AppTV y tvOS-X copian esa generación. El tvOS moderno es un catálogo de streaming:

- Barra superior de pestañas (Watch Now / Library / Search), no un menú lateral gordo.
- Un **hero** grande arriba (artwork de lo destacado o en curso).
- Debajo, **estanterías horizontales** (Continue Watching, Recently Added, Movies, Shows).
- Posters con esquinas redondeadas.
- El foco **escala**, levanta sombra y muestra el título; el resto se queda quieto.
- Fondo casi negro, tipografía grande, poco cromo, mucho espacio.
- Mando / D-pad como input principal. El ratón es secundario.

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
| Fork de Arctic Horizon 2 | Widgets potentes, look moderno | Compleja, depende de Skin Shortcuts + TMDbHelper | Fase 2 si hace falta |
| **Fork de Estuary (Omega/Piers)** | Completa, mantenida, widgets nativos, CC BY-SA 4.0 | Hay que destrozar el look (menú lateral, densidad) | **Base del MVP** |

Estuary ya tiene el patrón que necesitamos: `Home.xml` + includes `WidgetListPoster` que apuntan a `videodb://…` o playlists `.xsp`. El trabajo de producto es **cambiar el layout y el sistema visual**, no inventar el data binding.

Licencia: Estuary es CC BY-SA 4.0 / GPL-2.0. Aura debe atribuir y compartir bajo licencia compatible.

---

## 3. Límites del motor de Kodi (expectativas)

El skinning engine no es SwiftUI. Esto sí se puede:

- `wraplist` / `panel` horizontales = estanterías.
- Animaciones de foco: `<animation effect="zoom">`, fade, slide.
- Esquinas redondeadas vía texturas (máscaras PNG).
- Widgets de librería sin Python extra.
- Navegación D-pad explícita (`onup` / `ondown` / `onleft` / `onright`).

Esto no (o muy a medias):

- Parallax / tilt al mover el trackpad.
- Gaussian blur vivo del fanart (se finge con imagen oscurecida + viñeta).
- Tipografía variable y tracking fino de SF Pro.
- Layout fluido tipo `containerRelativeFrame` (todo es coordenadas 1920×1080).

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

El 80% de la percepción es Home + biblioteca + ficha + OSD. El resto puede quedar “Estuary oscuro” al principio.

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

### 5.4 Player OSD (DialogSeekBar)

Cromo mínimo: barra inferior, título, tiempo, transport. Sin paneles laterales enormes. Pause puede mostrar poster + sinopsis corta.

### 5.5 Resto (fase posterior)

Settings, PVR, música, addons, teclado, selectores: recolor + tipografía + focus tokens. Layout Estuary recortado. No se rediseñan hasta que Home/ficha/OSD se sientan bien.

---

## 6. Arquitectura del addon

```
skin.aura/
  addon.xml                 # id, xbmc.gui version, res 1920x1080
  xml/
    Home.xml                # pestañas + hero + shelves
    Includes.xml            # puntos de entrada
    Includes_Colors.xml     # tokens
    Includes_Focus.xml      # zoom/sombra del lockup
    Includes_Lockups.xml    # poster / landscape / hero
    Includes_Home.xml       # WidgetListPoster / Landscape
    MyVideoNav.xml          # vistas de biblioteca
    View_*.xml
    DialogVideoInfo.xml
    DialogSeekBar.xml
    …resto copiado de Estuary y retocado
  media/                    # PNG, máscaras, sombras (Textures.xbt al empaquetar)
  fonts/
  colors/defaults.xml
  language/resource.language.en_gb|es_es/strings.po
  playlists/                # .xsp de widgets
  resources/                # icon, fanart, screenshots
```

Resolución de trabajo: **1920×1080**. Otras aspectos después, si hace falta.

Dependencias del MVP: solo `xbmc.gui` (versión de Omega/Piers). Sin Skin Shortcuts, sin TMDbHelper. Eso mantiene la skin usable en un Pi / CoreELEC sin instalar media center extra.

Opcional más adelante: `script.skinshortcuts` para reordenar estanterías desde Settings.

---

## 7. Fases de trabajo

Cada fase termina en un zip instalable y una checklist de mando (arriba/abajo/ok/back).

### Fase 0 — Spec (este repo ahora)

- Plan y design system.
- Decisiones de naming, licencia, Kodi target.
- Inventario de ventanas Estuary que se tocan vs se heredan.

### Fase 1 — Scaffold

- Copiar Estuary Omega/Piers.
- Renombrar a `skin.aura` (addon id, carpeta, `addon.xml`).
- Paleta oscura + fuente + tokens de color.
- Empaquetar Textures.xbt, instalar en Kodi, confirmar que arranca.

### Fase 2 — Home Aura (prioridad máxima)

- Quitar el menú lateral de Estuary.
- Pestañas superiores.
- Hero + 3–5 estanterías con lockup Apple-like.
- Empty state.
- Skin settings mínimos: mostrar/ocultar estanterías.

**Criterio de éxito:** con el mando, en 3 segundos se entiende dónde está el foco y se puede reanudar algo.

### Fase 3 — Biblioteca + ficha

- Poster view alineada al lockup de Home.
- DialogVideoInfo tipo página de título.
- Navegación coherente Home → ficha → play.

### Fase 4 — OSD y búsqueda

- Seekbar / pause overlay limpios.
- Search como pestaña de primer nivel.

### Fase 5 — Pulido

- Música, PVR, addons, settings (recolor).
- Localización es/en.
- Capturas, icono, fanart.
- Rendimiento en hardware débil (límites de widgets, menos animaciones).

### Fuera de alcance del MVP

- Temas claro/oscuro múltiples.
- Personalización total tipo Arctic (cualquier nodo, cualquier widget).
- Clone pixel-perfect de tvOS.
- Soporte táctil/tablet como prioridad.
- 4K nativo / ultrawide.

---

## 8. Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Home “bonita” y el resto Estuary se siente roto | Tokens globales (color, fuente, focus) desde Fase 1 |
| Zoom de foco recorta posters | `scrolltime` + padding en wraplists; no clip del container |
| Demasiados widgets = lag en ARM | `limit` bajo (15–20); landscapes pesados solo en hero |
| xbmc.gui cambia entre Omega y Piers | Target una major; bump consciente |
| Marca Apple | Naming e iconografía propios; “inspired by”, no clone |
| Scope creep (PVR, karaoke, games…) | Estuary heredado hasta Fase 5 |

---

## 9. Cómo se prueba

Kodi en esta VM de desarrollo no es el entorno real. El loop previsto:

1. Editar XML en el repo.
2. Empaquetar `skin.aura` (zip o carpeta en `addons/`).
3. Instalar / reload skin (`ReloadSkin()`).
4. Probar con teclado como D-pad (flechas, enter, backspace).
5. Más adelante: CoreELEC / Windows HTPC con mando real.

Checklist por pantalla: foco visible, loop de navegación sin callejones, back vuelve a Home, play desde hero y desde poster.

---

## 10. Decisiones tomadas (para no bloquear)

1. **Producto:** skin Kodi, no frontend alternativo (Chorus, Jellyfin, etc.).
2. **Look:** tvOS moderno (shelves + hero + tabs), no icon grid ATV3.
3. **Base:** fork de Estuary, no from-scratch.
4. **Nombre de trabajo:** Aura.
5. **Target:** Kodi 21 Omega / 22 Piers, 1080p.
6. **Idioma de UI:** español + inglés.
7. **Dependencias extra:** ninguna en el MVP.

---

## 11. Siguiente paso de implementación

Cuando se pase de plan a código:

1. Vendor de Estuary (subtree o copia con atribución) → `skin.aura/`.
2. Design tokens en `colors/` + `Includes_Focus.xml` + `Includes_Lockups.xml`.
3. Reescribir `Home.xml` al layout de la sección 5.1.
4. Zip + instrucciones de instalación en el README.

Hasta entonces, este archivo y `docs/design-system.md` son la fuente de verdad.
