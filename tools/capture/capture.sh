#!/bin/bash
# Enregistre une visite guidée de l'appartement (capture.gd, Movie Maker de
# Godot) puis en extrait :
#   - les screenshots     export/Linux/screenshots/*.png (1536x900)
#   - le GIF de promotion export/promo/little_escape.gif (512x300, 10 images/s)
#
# La visite est reproductible (temps fixe à 30 images/s). Les plans (nom,
# première et dernière image) sont écrits par capture.gd : les screenshots et
# le GIF désignent les plans par leur nom, pas par des numéros d'image.
#
# Usage : ./tools/capture/capture.sh [dossier_images]
#   dossier_images : réutilise un enregistrement existant (f*.png + shots.txt)
#                    au lieu de relancer la visite
set -e

cd "$(dirname "$0")/../.."

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7-stable_linux.x86_64")}"
FPS=30
SIZE="1536x900"
SCREENSHOTS_DIR="export/Linux/screenshots"
GIF="export/promo/little_escape.gif"
# Screenshots (noms des plans de capture.gd, pris aux 2/3 du plan)
SHOTS="menu bedroom bathroom livingroom kitchen chessboard"
# GIF : plans enchaînés (une image sur trois)
GIF_SHOTS="bedroom livingroom kitchen chessboard end"

command -v ffmpeg >/dev/null || { echo "ffmpeg est requis" >&2; exit 1; }

if [ -n "$1" ]; then
	FRAMES_DIR="$1"
else
	if [ ! -x "$GODOT" ]; then
		echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
		exit 1
	fi
	if [ -e override.cfg ]; then
		echo "override.cfg existe déjà : le supprimer d'abord" >&2
		exit 1
	fi
	FRAMES_DIR="$(mktemp -d)"
	trap 'rm -rf "$FRAMES_DIR" override.cfg' EXIT
	# La taille de fenêtre du projet (1024x600, plein écran) l'emporte sur
	# --resolution : override.cfg temporaire pour enregistrer en $SIZE
	cat > override.cfg <<-EOF
		[display]

		window/size/mode=0
		window/size/window_width_override=${SIZE%x*}
		window/size/window_height_override=${SIZE#*x}
	EOF
	# Enregistrement (fenêtre visible : le Movie Maker a besoin du rendu, ~7 min)
	CAPTURE_SHOTS="$FRAMES_DIR/shots.txt" "$GODOT" --path . --fixed-fps "$FPS" \
		--write-movie "$FRAMES_DIR/f.png" -s "$PWD/tools/capture/capture.gd"
	rm -f override.cfg
fi

if [ ! -f "$FRAMES_DIR/shots.txt" ]; then
	echo "Plans introuvables ($FRAMES_DIR/shots.txt)" >&2
	exit 1
fi

frame() { printf "%s/f%08d.png" "$FRAMES_DIR" "$1"; }
shot_range() { # nom -> "première dernière"
	local range
	range="$(awk -v name="$1" '$1 == name { print $2, $3 }' "$FRAMES_DIR/shots.txt")"
	if [ -z "$range" ]; then
		echo "Plan inconnu : $1" >&2
		exit 1
	fi
	echo "$range"
}

mkdir -p "$SCREENSHOTS_DIR"
for name in $SHOTS; do
	read -r first last <<< "$(shot_range "$name")"
	cp "$(frame $(( first + (last - first) * 2 / 3 )))" "$SCREENSHOTS_DIR/$name.png"
done

# GIF : les premières images d'un plan montrent encore le chargement de la
# scène, on les saute
LIST="$FRAMES_DIR/gif.txt"
: > "$LIST"
for name in $GIF_SHOTS; do
	read -r first last <<< "$(shot_range "$name")"
	for ((i = first + 3; i <= last; i += 3)); do
		echo "file '$(frame "$i")'" >> "$LIST"
	done
done
mkdir -p "$(dirname "$GIF")"
ffmpeg -v error -y -f concat -safe 0 -r 10 -i "$LIST" \
	-vf "scale=512:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
	"$GIF"

echo "Screenshots : $SCREENSHOTS_DIR"
echo "GIF         : $GIF ($(du -h "$GIF" | cut -f1))"
