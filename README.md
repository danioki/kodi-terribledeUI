# Aura — skin de Kodi inspirada en Apple TV

Dos pilares: **Inicio** (Novedades primero, luego seguir viendo / películas / series) y **player** (audio, subtítulos y seek como un reproductor moderno).

## Estado

Implementación inicial (`skin.aura` 0.1.0), basada en Estuary (Kodi 22 / Piers, `xbmc.gui` 5.18).

## Instalar

1. Empaqueta la carpeta `skin.aura` en un zip (la raíz del zip debe ser `skin.aura/` con `addon.xml` dentro).
2. En Kodi 22: Settings → Add-ons → Install from zip file.
3. Settings → Interface → Skin → Aura.

O copia `skin.aura/` a `userdata/addons/` (o `~/.kodi/addons/`) y reinicia Kodi.

## Qué hay en 0.1.0

- Home a pantalla completa sin sidebar: tabs Search · Home · Movies · TV · Settings.
- Feed vertical: **Novedades** (películas + episodios), Seguir viendo, Películas, Series, Favoritos, Música, Directo, Addons.
- OSD mínimo: skip, play, Audio / CC con estado, Más; hojas de pistas abajo (Piers `DialogSelectAudio` / `DialogSelectSubtitle`).
- Paleta negra / foco blanco.

## Docs

- [PLAN.md](PLAN.md)
- [docs/home-ux.md](docs/home-ux.md)
- [docs/player-ux.md](docs/player-ux.md)
- [docs/design-system.md](docs/design-system.md)

## Licencia

Basada en Estuary (CC BY-SA 4.0 / GPL-2.0). Ver `skin.aura/LICENSE.txt`.
