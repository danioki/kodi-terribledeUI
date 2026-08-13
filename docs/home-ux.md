# Aura — Home

El home es un pilar, al mismo nivel que el player: **descubrir** qué hay de nuevo y **seguir** lo de siempre, sin sidebar de Estuary.

Spec hermana: [`player-ux.md`](player-ux.md).

---

## Orden de la pantalla (esto es el producto)

Al abrir Kodi, el feed de Inicio va **de arriba a abajo** así:

1. **Novedades** — lo último que entró en la librería. Primera sección, la más visible.
2. **Secciones normales** — Seguir viendo, Películas, Series, y el resto solo si hay contenido.

No al revés. No un menú lateral de “Movies / TV / Music” con widgets a la derecha. Un scroll vertical de estanterías, tipo Apple TV Watch Now.

```
┌─────────────────────────────────────────────────────────┐
  Search    Inicio    Películas    Series    [clock]
├─────────────────────────────────────────────────────────┤
│  HERO  (fanart del ítem enfocado en Novedades)          │
│  título · Play / Info                                   │
├─────────────────────────────────────────────────────────┤
│  Novedades                                              │
│    Películas     [■■] [■■] [■■] [■■] →                  │
│    Episodios     [■■] [■■] [■■] [■■] →                  │
│                                                         │
│  Seguir viendo   [■■] [■■] [■■] →                       │
│  Películas       [█] [█] [█] [█] [█] →                  │
│  Series          [█] [█] [█] [█] [█] →                  │
│  Favoritos       …  (si hay)                            │
│  Música / Directo / Addons  …  (si hay contenido)       │
└─────────────────────────────────────────────────────────┘
```

Foco inicial: primer ítem de **Novedades**. El hero sigue a ese foco.

---

## Novedades

En una librería local esto no es el “New on Apple TV” editorial. Es **recién añadido** (`dateadded`): lo que acabas de copiar, grabar o scrapear.

### Qué muestra

| Fila | Fuente | Lockup |
| --- | --- | --- |
| Películas nuevas | `videodb://recentlyaddedmovies` | Landscape 16:9 (más “banner” que poster) |
| Episodios nuevos | `videodb://recentlyaddedepisodes` | Landscape; label `Show · S02E04` |

Opcional con playlist `.xsp`: solo **no vistos**. Default del MVP: todos los recently added (si no se veían, no parecen novedad).

Límite: 15–20 por fila. Orden: más reciente primero.

### Cómo se siente

- Cabecera de sección **Novedades**, luego las dos filas. No dos bloques sueltos “Recently Added Movies” a mitad de página como Estuary.
- Lockup más grande que las secciones de abajo (landscape ~400×225 vs poster 220×330).
- Al enfocar un ítem: hero con fanart, título, año, Play / Info.
- Click: Play si es un episodio o película; Info también a un botón del hero.

No repetir esas mismas filas más abajo (nada de “Recently added” otra vez en Películas).

---

## Secciones normales (después de Novedades)

Solo se pintan si hay librería / contenido. Si no hay PVR, no hay fila de Directo.

| Orden | Sección | Fuente | Lockup |
| --- | --- | --- | --- |
| 1 | **Seguir viendo** | in-progress movies + `videodb://inprogresstvshows` | Landscape + barra de progreso |
| 2 | **Películas** | `videodb://movies/titles/` (o unwatched `.xsp`) | Poster 2:3 |
| 3 | **Series** | `videodb://tvshows/titles/` | Poster 2:3 |
| 4 | **Favoritos** | `favourites://` | Poster / icono |
| 5 | **Música** | `musicdb://recentlyaddedalbums/` | Cuadrado 1:1 |
| 6 | **Directo** | PVR / canales recientes | Landscape |
| 7 | **Addons** | `addons://sources/video/` | Icono, al final |

Seguir viendo va **después** de Novedades a propósito: primero “qué hay nuevo”, luego “dónde lo dejé”. En Apple TV a veces es al revés; aquí Novedades es la firma del home.

Películas / Series en el feed son un **atajo de estantería** (primeros títulos), no la biblioteca entera. La pestaña Películas / Series abre `MyVideoNav` (wall de posters).

---

## Pestañas

| Tab | Qué hace |
| --- | --- |
| Search | Búsqueda |
| **Inicio** | El feed de arriba (Novedades + secciones). Default al arrancar |
| Películas | Biblioteca movies |
| Series | Biblioteca TV |
| Reloj | derecha, no es tab |

Sin sidebar. Sin tab “Novedades” aparte: Novedades **es** el primer bloque de Inicio.

---

## Empty states

- Sin fuentes de vídeo: Inicio muestra un bloque “Añade películas o series”, no el wall de iconos de Estuary.
- Librería vacía de películas pero con series: se oculta la fila Películas (y la de Novedades → Películas).
- Sin in-progress: se oculta Seguir viendo. Novedades sigue.

---

## Navegación

- Arriba/abajo: cambia de estantería (Novedades películas → Novedades episodios → Seguir viendo → …).
- Izquierda/derecha: recorre la fila. Peek del siguiente ítem a la derecha.
- Back en Inicio: no abre un menú de apagado a la primera; el shutdown sigue en un long-press / tab de sistema (Estuary lo pone agresivo).
- Play desde Novedades o Seguir viendo entra al player de [`player-ux.md`](player-ux.md).

---

## Criterio de éxito (demo)

Librería con 3 películas nuevas, 2 episodios nuevos y 1 capítulo a medias:

1. Arranca Kodi. Se ve **Novedades** sin buscarla.
2. El hero es la primera novedad. OK → Play o Info, a elección.
3. Abajo: episodios nuevos, luego Seguir viendo (el capítulo a medias, con progreso).
4. Más abajo: Películas y Series como posters.
5. No hay duplicados de “recently added”. No hay sidebar.

---

## Archivos

| Archivo | Rol |
| --- | --- |
| `Home.xml` | Tabs + hero + orden de widgets |
| `Includes_Home.xml` | `WidgetListNovedades` (landscape) + posters |
| `playlists/*.xsp` | unwatched / in-progress si hace falta mezclar |
| `Includes_Lockups.xml` | landscape novedades vs poster vs progreso |
