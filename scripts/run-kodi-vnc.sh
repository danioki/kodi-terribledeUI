#!/usr/bin/env bash
# Launch Kodi on the cloud agent desktop (DISPLAY=:1) with Aura linked + enabled.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KODI_HOME="${KODI_HOME:-$HOME/.kodi}"
DISPLAY_NUM="${DISPLAY:-:1}"

mkdir -p "$KODI_HOME/addons" "$KODI_HOME/userdata/Database"
ln -sfn "$ROOT/skin.aura" "$KODI_HOME/addons/skin.aura"

if [[ ! -f "$KODI_HOME/userdata/guisettings.xml" ]]; then
  cat > "$KODI_HOME/userdata/guisettings.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<settings version="2">
    <setting id="lookandfeel.skin" default="false">skin.aura</setting>
    <setting id="locale.language">resource.language.es_es</setting>
    <setting id="services.webserver">true</setting>
    <setting id="services.webserverport">8080</setting>
    <setting id="services.webserverauthentication">false</setting>
</settings>
XML
fi

if [[ ! -f "$KODI_HOME/userdata/advancedsettings.xml" ]]; then
  cat > "$KODI_HOME/userdata/advancedsettings.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<advancedsettings version="1.0">
  <showexitbutton>true</showexitbutton>
  <splash>false</splash>
  <loglevel hide="false">1</loglevel>
</advancedsettings>
XML
fi

# First boot may mark a new skin incompatible until enabled in Addons DB.
python3 - <<PY
import sqlite3, glob, os
db_glob = os.path.expanduser("$KODI_HOME/userdata/Database/Addons*.db")
for db in glob.glob(db_glob):
    con = sqlite3.connect(db)
    try:
        con.execute(
            "UPDATE installed SET enabled=1, disabledReason=0 WHERE addonID='skin.aura'"
        )
        con.commit()
        print(f"enabled skin.aura in {db}")
    except sqlite3.Error as e:
        print(f"skip {db}: {e}")
    finally:
        con.close()
PY

export DISPLAY="$DISPLAY_NUM"
export KODI_DATA="$KODI_HOME"

echo "DISPLAY=$DISPLAY"
echo "skin -> $KODI_HOME/addons/skin.aura"
echo "Desktop: TigerVNC :1 / noVNC (port 26058 in this agent image)"
echo "After edits: Input.ExecuteAction reloadskin via JSON-RPC once webserver is up"

exec kodi --windowing=x11 "$@"
