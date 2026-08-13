# Aura — experiencia de reproducción

El producto se juega **mientras se ve** una película o un capítulo, no en el menú de inicio. Subtítulos, pista de audio, seek y el siguiente episodio tienen que sentirse como un reproductor de streaming (Apple TV / Disney+ / Netflix), no como los ajustes de Estuary.

Este archivo es la spec de esa experiencia. El look de Home es secundario.

---

## Problema que resolvemos

En Kodi, cambiar de idioma o de subtítulos suele ser:

1. OK → OSD de botones.
2. Botón Subtítulos o Audio → **otro** diálogo de settings.
3. Recorrer una lista de opciones técnicas (delay, volume amp, passthrough…).
4. A veces `CycleSubtitle` que rota pistas a ciegas, sin ver el listado.
5. Descargar un SRT es otra ventana (`DialogSubtitles`).
6. El vídeo se tapa con paneles laterales enormes.

Un reproductor moderno hace esto:

- Un toque enseña cromo mínimo (título, barra, 5 acciones).
- Audio y subtítulos viven **juntos**, en una hoja.
- Se ve la pista actual y se elige otra en un click.
- Off de subtítulos es un ítem de la lista, no un setting escondido.
- Delay, tamaño de fuente y passthrough no aparecen hasta “Más”.

---

## Principio: dos capas

| Capa | Para qué | Qué hay |
| --- | --- | --- |
| **Ver** | 99% de las sesiones | Play/pause, skip ±10s, seek, Audio, CC, siguiente capítulo |
| **Ajustar** | Cuando algo falla | Delay audio/subs, tamaño, posición, boost, stream de vídeo, codec info |

Si el usuario entra en “Ajustar” para cambiar de español a inglés, la skin ha fallado.

---

## Overlay principal (capa Ver)

Un solo cromo inferior. `VideoOSD.xml` + `DialogSeekBar.xml` se **ven** como una pieza, aunque Kodi los trate como ventanas distintas.

```
  Dune: Part Two                                          −1:04:12
  [████████████●────────────────────────]     1:14:08 / 2:18:20

     ⟲ 10s     ❚❚     10s ⟳      Audio ES 5.1      CC Off      ···
```

### Qué se muestra siempre (cuando el OSD está up)

- Título. Si es serie: `Show · S02E04 · nombre del capítulo`.
- Tiempo transcurrido / restante (restante es el dato útil en el sofá).
- Barra de progreso con capítulo markers si el archivo tiene chapters.
- Cinco acciones, no quince iconos de Estuary.

### Acciones del OSD (orden L→R)

| Control | Acción Kodi | Nota |
| --- | --- | --- |
| Skip back 10s | `Seek(-10)` / `PlayerControl(SmallSkipBackward)` | Siempre visible |
| Play / Pause | `PlayerControl(Play)` | Foco por defecto al abrir OSD |
| Skip forward 10s | `Seek(10)` | |
| **Audio** | abre hoja de pistas | Label = idioma actual + canales (`ES · 5.1`) |
| **CC** | abre la misma hoja, foco en subtítulos | Label = `Off` o idioma actual. Icono tachado si off |
| Más (`···`) | capa Ajustar | Delay, vídeo, info de stream, buscar SRT |

No hay botones de “codec”, “stereo upmix”, “bookmark” ni “watched” en esta barra.

### Comportamiento

- OK / Select en fullscreen → muestra OSD. Segundo OK sobre Play → pause.
- Back / OSD timeout (~4 s, más si hay foco en un botón) → cromo se va. El vídeo nunca se pausa al abrir el OSD.
- Izquierda / derecha **sobre la barra** = seek. Izquierda / derecha **sobre skip** = el skip.
- Arriba desde la barra → nada (no un menú que cubra la cara de los actores).
- Abajo desde la barra → abre la **hoja Audio y subtítulos** (gesto mental tipo swipe-down de tvOS).
- En series, si hay siguiente ítem en playlist: botón extra `Siguiente episodio` a la derecha, o al terminar.

Pause largo (el usuario se levantó): overlay un poco más rico — poster + sinopsis corta + las mismas acciones. No un dashboard.

---

## Hoja Audio y subtítulos (el entregable clave)

Una ventana, dos columnas. No settings. No cycle ciego.

```
┌───────────────────────────┬───────────────────────────┐
│  Audio                    │  Subtítulos               │
│                           │                           │
│  ● Español                │  ○ Off                    │
│    EAC3  5.1              │                           │
│                           │  ● Español                │
│    English                │    Forced                 │
│    TrueHD  7.1            │                           │
│                           │    English (SDH)          │
│    Commentary             │                           │
│    AC3  2.0               │    Buscar más…            │
└───────────────────────────┴───────────────────────────┘
```

Reglas:

1. **Idioma primero**, codec/canales en segunda línea (gris). Nadie elige “EAC3” de oídas.
2. Pista activa = tick + peso semibold. Default del archivo = opcional, no compite con el tick.
3. Primera fila de subtítulos = **Off** (`ShowSubtitles` / disable). Siempre.
4. `Buscar más…` abre `DialogSubtitles` (descarga). Está al final, no al principio.
5. Un click aplica y **cierra** la hoja. El vídeo sigue. Confirmación visual 1 s en el OSD (`Audio · English 7.1`).
6. Si solo hay una pista de audio, la columna audio se muestra igual (no se esconde: da confianza).
7. Forced subs no se “apagan” con Off si el motor las fuerza; el label debe decirlo.

### Cómo se implementa en Kodi

Kodi 22 **Piers** añadió exactamente las ventanas que hacen falta:

- `DialogSelectAudio` (`ActivateWindow(DialogSelectAudio)`)
- `DialogSelectSubtitle` (`ActivateWindow(DialogSelectSubtitle)`)

El motor lista las pistas, marca default y activa, y deja a la skin el XML (`DialogSelect.xml` por tipo).

**Plan A (MVP, Piers):** skinear esos dos diálogos para que parezcan las dos columnas de arriba. El botón Audio abre el de audio; CC el de subs. Visualmente, mismo chrome (misma include), para que no se sientan ventanas distintas.

**Plan B (mejor, un poco más de XML):** custom window `Custom_1102_PlayerStreams.xml` que embebe o dispara ambos selectores en un layout de dos columnas. Si el engine no permite dos selectores a la vez, Plan A.

**Omega 21:** no hay esos diálogos. Ahí solo existen `CycleSubtitle`, `osdaudiosettings` y listas en settings. No se puede listar pistas con la misma calidad. **Target del player: Piers (Kodi 22).** Omega queda fuera del MVP de reproducción, o un fallback pobre (cycle + toast de `VideoPlayer.AudioLanguage`).

Info labels útiles en el OSD:

- `VideoPlayer.AudioLanguage`, `VideoPlayer.AudioCodec`, `VideoPlayer.AudioChannels`
- `VideoPlayer.SubtitlesLanguage`, `VideoPlayer.SubtitlesEnabled`, `VideoPlayer.HasSubtitles`
- `VideoPlayer.AudioStreamCount` (Piers)
- `Player.Time`, `Player.Duration`, `Player.TimeRemaining`
- `VideoPlayer.Title`, `VideoPlayer.TVShowTitle`, `VideoPlayer.Season`, `VideoPlayer.Episode`

---

## Capa Ajustar (`···`)

Un sheet estrecho, no el DialogSettings de 15 filas de Estuary.

Grupo 1 — sync (lo que la gente busca de verdad):

- Subtitle delay (`PlayerControl(SubtitleDelayMinus/Plus)` o slider)
- Audio delay

Grupo 2 — pinta de subs:

- Tamaño / posición (los settings de `osdsubtitlesettings` que importan)

Grupo 3 — raros:

- Pista de vídeo (`DialogSelectVideo`)
- Info de proceso (codec, HDR) — `PlayerProcessInfo`, oculto detrás de “Info”
- Bookmark / watched

Nunca mezclar esto con la elección de idioma.

---

## Series: que no se rompa el flow

- Al terminar un capítulo, overlay de **siguiente episodio** (poster + “Reproduce en 5 s” + Cancelar). Kodi: playlist / `PlayNext` / `Player.HasNext`.
- Botón `Siguiente` en el OSD si `Player.HasNext`.
- Intro skip solo si hay **chapters** en el archivo (`Player.ChapterCount`). Un botón “Siguiente capítulo” cuando el chapter se llama Intro/Opening, si el label existe. Sin magia de ML en el MVP.
- Up Next de addons de terceros: no depender de ellos en el MVP; el overlay nativo basta.

---

## Mando y teclas (keymap de skin)

| Input | Fullscreen | OSD abierto | Hoja de pistas |
| --- | --- | --- | --- |
| OK | Abrir OSD | Pause si foco en play | Aplicar pista |
| Back | (nada / stop según setting Kodi) | Cerrar OSD | Cerrar hoja, OSD sigue |
| ← → | Skip 10s *o* seek (decisión: skip) | Mover foco / seek en barra | Cambiar de columna |
| ↓ | Abrir hoja Audio+CC | Hoja Audio+CC | — |
| Lang / Subtitle keys | Abrir hoja en la columna correcta | igual | igual |

Cycle ciego (`CycleSubtitle` en una tecla suelta) se puede dejar como atajo avanzado, con toast `ES → EN → Off`. No es el camino principal.

---

## Lo que *no* es seamless (anti-patrones Kodi)

- `CycleSubtitle` como único UI.
- Mandar a `osdaudiosettings` para cambiar de idioma.
- Panel que cubre el centro de la imagen.
- Pausar el vídeo al abrir el menú de pistas.
- Cinco ventanas distintas (OSD, seek, audio settings, subtitle settings, subtitle search, process info).
- Labels `Audio stream 3` sin idioma.
- ALL CAPS y botones de 48 px apelotonados.

---

## Criterio de éxito (demo)

Con un MKV que tenga 2 audios y 3 subs, mando en mano:

1. Play desde la ficha. No hay chrome. Se ve la película.
2. OK → barra + título. El vídeo **sigue**.
3. Ir a CC → elegir English → un click. Subs cambian. La hoja se cierra.
4. Abajo → Audio → Español. Un click.
5. Skip 10s dos veces. Seek en la barra. Back. Pantalla limpia.
6. En una serie, al acabar: siguiente episodio sin volver al menú.

Si el paso 3 o 4 exige entrar en “Settings”, no está hecho.

---

## Archivos de skin implicados

| Archivo | Rol |
| --- | --- |
| `VideoOSD.xml` | Cromo inferior, 5 acciones |
| `DialogSeekBar.xml` | Barra + tiempos; alinear con el OSD |
| `DialogSelect.xml` (audio/subs/video) | Listas de pistas, look de hoja |
| `Custom_1102_PlayerStreams.xml` | Opcional, dos columnas |
| `DialogSubtitles.xml` | Descarga SRT, mismo look |
| `DialogPlayerProcessInfo.xml` | Capa Ajustar → Info |
| `DialogSettings.xml` | Solo lo que quede en `···` |
| `addon.xml` + keymap | Atajos ↓ / lang |

Home e Inicio se especifican en [`home-ux.md`](home-ux.md): Novedades primero, luego las secciones normales. Play desde ahí entra a este player.
