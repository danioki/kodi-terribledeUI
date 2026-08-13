# Aura — skin de Kodi inspirada en Apple TV

Dos pilares: **Inicio** (Novedades primero, luego seguir viendo / películas / series) y **player** (audio, subtítulos y seek como un reproductor moderno).

## Estado

Implementación inicial (`skin.aura` 0.1.0), basada en Estuary. Probada en esta VM con **Kodi 20.5 + VNC** (Home OK; hojas de pistas de Piers pendientes de Kodi 22).

## Probar en la VM / escritorio VNC

Este environment ya trae XFCE + TigerVNC + noVNC. Con Kodi instalado:

```bash
scripts/run-kodi-vnc.sh
```

Detalle: [docs/testing.md](docs/testing.md).

## Instalar en un HTPC

1. Empaqueta `skin.aura/` en un zip (raíz = carpeta con `addon.xml`).
2. Kodi → Add-ons → Install from zip.
3. Interface → Skin → Aura.

Ideal: **Kodi 22 Piers** para Audio/CC sheets. En 20/21 sirve para validar Home.

## Docs

- [PLAN.md](PLAN.md)
- [docs/home-ux.md](docs/home-ux.md)
- [docs/player-ux.md](docs/player-ux.md)
- [docs/design-system.md](docs/design-system.md)
- [docs/testing.md](docs/testing.md)

## Licencia

Basada en Estuary (CC BY-SA 4.0 / GPL-2.0). Ver `skin.aura/LICENSE.txt` y `NOTICE.md`.
