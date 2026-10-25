#!/bin/bash
# Génère les screenshots export/Linux/screenshots/*.png (1536x900) sans
# enregistrer toute la visite ni le GIF (voir capture.sh) : quelques secondes
# au lieu de ~7 minutes, ffmpeg n'est pas nécessaire.
#
# Les plans (scène, position de la caméra) sont ceux de capture.gd.
#
# Usage : ./tools/capture/screenshots.sh [plan...]
#   plan : noms des plans de capture.gd (par défaut ceux de l'appdata/README)
#   ex.  : ./tools/capture/screenshots.sh bedroom kitchen
set -e

cd "$(dirname "$0")/../.."

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7-stable_linux.x86_64")}"
FPS=30
SIZE="1536x900"
SCREENSHOTS_DIR="export/Linux/screenshots"

if [ ! -x "$GODOT" ]; then
	echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
	exit 1
fi
if [ -e override.cfg ]; then
	echo "override.cfg existe déjà : le supprimer d'abord" >&2
	exit 1
fi

trap 'rm -f override.cfg' EXIT
# La taille de fenêtre du projet (1024x600, plein écran) l'emporte sur
# --resolution : override.cfg temporaire pour rendre en $SIZE
cat > override.cfg <<-EOF
	[display]

	window/size/mode=0
	window/size/window_width_override=${SIZE%x*}
	window/size/window_height_override=${SIZE#*x}
EOF

# Fenêtre visible : le rendu est nécessaire pour les screenshots
SCREENSHOTS_SHOTS="$*" SCREENSHOTS_DIR="$PWD/$SCREENSHOTS_DIR" \
	"$GODOT" --path . --fixed-fps "$FPS" -s "$PWD/tools/capture/screenshots.gd"

echo "Screenshots : $SCREENSHOTS_DIR"
