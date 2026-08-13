# Aura — skin de Kodi inspirada en Apple TV

Dos pilares: **Inicio** (Novedades primero, luego seguir viendo / películas / series) y **player** (audio, subtítulos y seek como un reproductor moderno).

## Estado

Implementación inicial (`skin.aura` 0.1.0), basada en Estuary. Pensada para instalarse en **tu Kodi local** (HTPC / LibreELEC / Windows / etc.). Ideal en Kodi 22 (Piers) para Audio/CC; en 20/21 el Home ya se puede mirar.

## Instalar en local

```bash
git clone https://github.com/danioki/kodi-terribledeUI.git
cd kodi-terribledeUI
git checkout cursor/aura-skin-impl-87c0
cd skin.aura && zip -r ../skin.aura.zip . && cd ..
```

En Kodi: **Add-ons → Install from zip file** → `skin.aura.zip` → **Ajustes → Interfaz → Skin → Aura**.

Sin zip, copia la carpeta `skin.aura` a:

- Windows: `%APPDATA%\Kodi\addons\`
- Linux: `~/.kodi/addons/`
- LibreELEC / CoreELEC: `/storage/.kodi/addons/`

## Docs

- [PLAN.md](PLAN.md)
- [docs/home-ux.md](docs/home-ux.md)
- [docs/player-ux.md](docs/player-ux.md)
- [docs/design-system.md](docs/design-system.md)

## Licencia

Basada en Estuary (CC BY-SA 4.0 / GPL-2.0). Ver `skin.aura/LICENSE.txt` y `NOTICE.md`.
