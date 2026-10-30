#!/bin/bash
# Génère uniquement le GIF de promotion export/promo/little_escape.gif
# (512x300, 10 images/s) : seuls les plans du GIF sont enregistrés
# (CAPTURE_ONLY de capture.gd), environ 1 min 30 au lieu de ~7 minutes pour
# toute la visite (voir capture.sh).
#
# Usage : ./tools/capture/gif.sh [dossier_images]
#   dossier_images : réutilise un enregistrement existant (f*.png + shots.txt,
#                    de gif.sh ou capture.sh) au lieu de relancer la visite
#   GIF_SHOTS="..." : plans du GIF, dans l'ordre (noms des plans de capture.gd)
#   KEEP_FRAMES=1  : garde les images enregistrées (dossier affiché à la fin)
set -e

cd "$(dirname "$0")/../.."

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7-stable_linux.x86_64")}"
FPS=30
SIZE="1536x900"
GIF="export/promo/little_escape.gif"
# Plans enchaînés (une image sur trois)
GIF_SHOTS="${GIF_SHOTS:-bedroom livingroom kitchen chessboard end}"

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
	if [ -n "$KEEP_FRAMES" ]; then
		trap 'rm -f override.cfg' EXIT
	else
		trap 'rm -rf "$FRAMES_DIR" override.cfg' EXIT
	fi
	# La taille de fenêtre du projet (1024x600, plein écran) l'emporte sur
	# --resolution : override.cfg temporaire pour enregistrer en $SIZE
	cat > override.cfg <<-EOF
		[display]

		window/size/mode=0
		window/size/window_width_override=${SIZE%x*}
		window/size/window_height_override=${SIZE#*x}
	EOF
	# Enregistrement (fenêtre visible : le Movie Maker a besoin du rendu)
	CAPTURE_ONLY="$GIF_SHOTS" CAPTURE_SHOTS="$FRAMES_DIR/shots.txt" "$GODOT" --path . \
		--fixed-fps "$FPS" --write-movie "$FRAMES_DIR/f.png" -s "$PWD/tools/capture/capture.gd"
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

# Les premières images d'un plan montrent encore le chargement de la scène,
# on les saute
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

echo "GIF : $GIF ($(du -h "$GIF" | cut -f1))"
if [ -n "$KEEP_FRAMES" ] && [ -z "$1" ]; then
	echo "Images : $FRAMES_DIR"
fi
