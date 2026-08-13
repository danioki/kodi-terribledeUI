# Probar Aura en este entorno (VM / contenedor)

Sí se puede emular aquí. Esta máquina **ya tiene** escritorio gráfico:

| Pieza | Valor |
| --- | --- |
| Desktop | XFCE en `DISPLAY=:1` |
| VNC | TigerVNC `localhost:5901` |
| noVNC | puerto `26058` (browser) |
| Kodi instalado | **20.5 Nexus** (apt Ubuntu 24.04) |

## Límites honestos

1. **Versión:** apt da Kodi 20.5, no Piers 22. Home se puede probar. Las hojas `DialogSelectAudio` / `DialogSelectSubtitle` son de Piers; en Nexus esos botones del OSD no tendrán el diálogo nuevo.
2. **Vídeo / HDR / passthrough:** sin GPU real ni mando; sirve para UI y foco, no para calibrar reproducción.
3. **Headless puro** (`linuxserver/kodi-headless`): **no** sirve para skins — no hay GUI.

## Arranque rápido (ya preparado)

```bash
# una vez por máquina (Ubuntu)
sudo apt-get install -y kodi

chmod +x scripts/run-kodi-vnc.sh
scripts/run-kodi-vnc.sh
```

En el agent cloud de Cursor el escritorio ya está en `DISPLAY=:1` (TigerVNC + noVNC). El script enlaza `skin.aura`, fuerza `enabled=1` en la DB de addons (si Kodi la marcó incompatible al primer boot) y lanza Kodi.

Comprobado: Home Aura carga (tabs Buscar / Inicio / Películas / Series / Ajustes + empty state en español).

Recargar skin sin reiniciar (JSON-RPC, cuando el webserver escuche en 8080):

```bash
curl -s -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"Input.ExecuteAction","params":{"action":"reloadskin"},"id":1}' \
  http://127.0.0.1:8080/jsonrpc
```

## Rutas hacia Kodi 22 (Piers) más adelante

| Opción | GUI skin? | Notas |
| --- | --- | --- |
| Apt 20.5 + VNC (**actual**) | Sí | Bueno para Home |
| Flatpak Flathub (Omega 21) | Sí | Mejor aproximación; aún sin DialogSelect de Piers |
| Debs comunitarios Omega | Sí | p.ej. kodi-ubuntu-debs |
| Docker + Kodi + TigerVNC/noVNC | Sí | Reproducible; imagen propia |
| linuxserver/kodi-headless | No | Solo librería / web |

Cuando Piers llegue a Flatpak o a un `.deb`, se sube `xbmc.gui` a `5.18.0` otra vez y se valida el OSD completo.

## Contenedor (opcional)

Hay un `docker/kodi-novnc/` de referencia. Requiere Docker en la imagen base del environment. En este agent hoy no hay Docker; el camino VNC local es el que funciona ya.

## Checklist manual con mando/teclado

1. Arranca → Inicio sin sidebar, **Novedades** arriba.
2. Flechas: estanterías; foco escala.
3. Play de un archivo de prueba (meter uno en `~/Videos`).
4. OK → OSD; Audio / CC (en Piers: hoja; en Nexus: puede fallar el window).
