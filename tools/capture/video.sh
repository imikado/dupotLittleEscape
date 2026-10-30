#!/bin/bash
# Enregistre la visite guidée de l'appartement (capture.gd, Movie Maker de
# Godot) en 1920x1080 puis monte la vidéo de promotion pour YouTube
# export/promo/little_escape.mp4 : écran titre, plans légendés enchaînés en
# fondu, écran de fin avec les liens.
#
# Les plans sont désignés par leur nom (voir capture.gd et shots.txt).
#
# Usage : ./tools/capture/video.sh [dossier_images]
#   dossier_images : réutilise un enregistrement existant (f*.png + shots.txt)
#                    au lieu de relancer la visite
#   MUSIC=fichier  : piste audio (coupée et fondue à la durée de la vidéo),
#                    sinon piste silencieuse
set -e

cd "$(dirname "$0")/../.."

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7-stable_linux.x86_64")}"
FPS=30
SIZE="1920x1080"
VIDEO="export/promo/little_escape.mp4"
FONT="$PWD/Ubuntu-B.ttf"
ICON="export/Linux/flatpak/icons/256x256.png"
# Durée des fondus entre les plans (s)
FADE=0.5
TITLE_DURATION=4
END_DURATION=6
# Plans de la vidéo, dans l'ordre : nom|légende (vide : pas de légende)
VIDEO_SHOTS=(
	"bedroom|You wake up locked in a small flat"
	"bedroom_clock|Search every room"
	"closet|Look closely at every object"
	"bathroom|Find the hidden keys"
	"livingroom|Every room opens the way to the next one"
	"chessboard|Solve the puzzles"
	"remote_control|"
	"livingroom_laptop|Clues are everywhere"
	"kitchen|"
	"kitchen_secret_box|Crack the secret codes"
	"exit|Can you escape?"
)

command -v ffmpeg >/dev/null || { echo "ffmpeg est requis" >&2; exit 1; }

WORK_DIR="$(mktemp -d)"
if [ -n "$1" ]; then
	FRAMES_DIR="$1"
	trap 'rm -rf "$WORK_DIR"' EXIT
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
	trap 'rm -rf "$FRAMES_DIR" "$WORK_DIR" override.cfg' EXIT
	# La taille de fenêtre du projet (1024x600, plein écran) l'emporte sur
	# --resolution : override.cfg temporaire pour enregistrer en $SIZE, en
	# 16:9 sans bandes noires (aspect "expand") et sans bordure de fenêtre
	cat > override.cfg <<-EOF
		[display]

		window/size/mode=0
		window/size/borderless=true
		window/size/window_width_override=${SIZE%x*}
		window/size/window_height_override=${SIZE#*x}
		window/stretch/aspect="expand"
	EOF
	# Enregistrement (fenêtre visible : le Movie Maker a besoin du rendu)
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

# Mise au format quelle que soit la taille réelle de la fenêtre enregistrée
FIT="scale=${SIZE%x*}:${SIZE#*x}:force_original_aspect_ratio=decrease,pad=${SIZE%x*}:${SIZE#*x}:-1:-1,setsar=1,fps=$FPS,format=yuv420p"
ENCODE=(-c:v libx264 -preset slow -crf 14 -pix_fmt yuv420p -r "$FPS")

# texte apparaissant et disparaissant en fondu sur une durée $2
fading_text() { # fichier_texte durée taille y [début]
	local start="${5:-0.3}"
	echo "drawtext=fontfile='$FONT':textfile='$1':fontsize=$3:fontcolor=white:borderw=4:bordercolor=black@0.85:x=(w-text_w)/2:y=$4:alpha='clip(min((t-$start)/0.4\,($2-0.3-t)/0.4)\,0\,1)'"
}

SEGMENTS=()

# Écran titre : image floutée et assombrie de la chambre, icône, titre
read -r first last <<< "$(shot_range bedroom)"
echo "Little Escape" > "$WORK_DIR/title.txt"
echo "A cartoon escape game" > "$WORK_DIR/subtitle.txt"
ffmpeg -v error -y -loop 1 -t "$TITLE_DURATION" -framerate "$FPS" -i "$(frame "$first")" \
	-loop 1 -t "$TITLE_DURATION" -framerate "$FPS" -i "$ICON" \
	-filter_complex "[0:v]$FIT,boxblur=20:2,eq=brightness=-0.25,zoompan=z='1+0.0008*on':d=1:s=$SIZE:fps=$FPS[bg];\
[1:v]format=rgba,fade=in:st=0.2:d=0.6:alpha=1[icon];\
[bg][icon]overlay=(W-w)/2:H*0.17,\
$(fading_text "$WORK_DIR/title.txt" "$TITLE_DURATION" 150 h*0.52 0.5),\
$(fading_text "$WORK_DIR/subtitle.txt" "$TITLE_DURATION" 64 h*0.70 0.9),format=yuv420p" \
	"${ENCODE[@]}" "$WORK_DIR/s000.mp4"
SEGMENTS+=("$WORK_DIR/s000.mp4")

# Plans légendés (les premières images d'un plan montrent encore le
# chargement de la scène, on les saute)
i=1
for entry in "${VIDEO_SHOTS[@]}"; do
	name="${entry%%|*}"
	caption="${entry#*|}"
	read -r first last <<< "$(shot_range "$name")"
	first=$((first + 3))
	count=$((last - first + 1))
	duration="$(echo "scale=3; $count / $FPS" | bc)"
	filter="$FIT"
	if [ -n "$caption" ]; then
		echo "$caption" > "$WORK_DIR/caption$i.txt"
		filter="$filter,$(fading_text "$WORK_DIR/caption$i.txt" "$duration" 72 h*0.80)"
	fi
	segment="$(printf "%s/s%03d.mp4" "$WORK_DIR" "$i")"
	ffmpeg -v error -y -framerate "$FPS" -start_number "$first" -i "$FRAMES_DIR/f%08d.png" \
		-frames:v "$count" -vf "$filter" "${ENCODE[@]}" "$segment"
	SEGMENTS+=("$segment")
	i=$((i + 1))
done

# Écran de fin : image floutée de l'écran de fin du jeu, liens
read -r first last <<< "$(shot_range end)"
printf "Little Escape  -  Free\n" > "$WORK_DIR/end1.txt"
printf "Play in your browser: dupot-org.itch.io/little-escape\n" > "$WORK_DIR/end2.txt"
printf "Linux: Flathub  -  Snap Store\n" > "$WORK_DIR/end3.txt"
printf "dupot.org  -  Made with Godot\n" > "$WORK_DIR/end4.txt"
ffmpeg -v error -y -loop 1 -t "$END_DURATION" -framerate "$FPS" -i "$(frame "$last")" \
	-loop 1 -t "$END_DURATION" -framerate "$FPS" -i "$ICON" \
	-filter_complex "[0:v]$FIT,boxblur=20:2,eq=brightness=-0.3[bg];\
[1:v]format=rgba,scale=200:-1,fade=in:st=0.2:d=0.6:alpha=1[icon];\
[bg][icon]overlay=(W-w)/2:H*0.10,\
$(fading_text "$WORK_DIR/end1.txt" "$((END_DURATION + 1))" 110 h*0.36 0.3),\
$(fading_text "$WORK_DIR/end2.txt" "$((END_DURATION + 1))" 58 h*0.55 0.8),\
$(fading_text "$WORK_DIR/end3.txt" "$((END_DURATION + 1))" 58 h*0.65 1.1),\
$(fading_text "$WORK_DIR/end4.txt" "$((END_DURATION + 1))" 44 h*0.80 1.4),\
fade=out:st=$(echo "$END_DURATION - 0.8" | bc):d=0.8,format=yuv420p" \
	"${ENCODE[@]}" "$(printf "%s/s%03d.mp4" "$WORK_DIR" "$i")"
SEGMENTS+=("$(printf "%s/s%03d.mp4" "$WORK_DIR" "$i")")

# Enchaînement en fondu des segments
inputs=()
filter=""
previous="[0:v]"
offset=0
for ((n = 0; n < ${#SEGMENTS[@]}; n++)); do
	inputs+=(-i "${SEGMENTS[$n]}")
	length="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "${SEGMENTS[$n]}")"
	if [ "$n" -gt 0 ]; then
		filter="$filter${previous}[$n:v]xfade=transition=fade:duration=$FADE:offset=$offset[v$n];"
		previous="[v$n]"
	fi
	offset="$(echo "$offset + $length - $FADE" | bc)"
done
total="$(echo "$offset + $FADE" | bc)"
filter="$filter${previous}fade=in:st=0:d=0.5[v]"

if [ -n "$MUSIC" ]; then
	inputs+=(-i "$MUSIC")
	audio="[${#SEGMENTS[@]}:a]atrim=0:$total,afade=in:st=0:d=1,afade=out:st=$(echo "$total - 2" | bc):d=2[a]"
else
	inputs+=(-f lavfi -t "$total" -i anullsrc=channel_layout=stereo:sample_rate=48000)
	audio="[${#SEGMENTS[@]}:a]anull[a]"
fi

mkdir -p "$(dirname "$VIDEO")"
ffmpeg -v error -y "${inputs[@]}" -filter_complex "$filter;$audio" \
	-map "[v]" -map "[a]" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
	-profile:v high -r "$FPS" -c:a aac -b:a 192k -movflags +faststart -t "$total" "$VIDEO"

echo "Vidéo : $VIDEO (${total}s, $(du -h "$VIDEO" | cut -f1))"
