extends SceneTree
# Génère les icônes PNG à partir de tools/icons/icon.svg :
# - appdata Flathub (export/Linux/flatpak/icons/)
# - Snap Store (export/Linux/snap/snap/gui/)
# - icône du projet Godot (icon.png : fenêtre, export HTML5)
#
# Usage : godot --headless --path . -s tools/icons/generate_icons.gd

const SOURCE="res://tools/icons/icon.svg"
const FLATPAK_DIR="res://export/Linux/flatpak/icons"
const FLATPAK_SIZES=[16,24,32,48,64,128,256,512]
const SNAP_ICON="res://export/Linux/snap/snap/gui/dupot-little-escape.png"
const PROJECT_ICON="res://icon.png"

func _initialize():
	# tools/ et export/ sont ignorés par Godot (.gdignore) : lecture directe des fichiers
	var svg=FileAccess.get_file_as_string(ProjectSettings.globalize_path(SOURCE))
	for size in FLATPAK_SIZES:
		_render(svg,size,"%s/%dx%d.png"%[FLATPAK_DIR,size,size])
	_render(svg,256,SNAP_ICON)
	_render(svg,256,PROJECT_ICON)
	quit()

func _render(svg:String,size:int,output:String):
	var image=Image.new()
	# rendu vectoriel à la taille finale (net même en 512)
	image.load_svg_from_string(svg,size/256.0)
	var path=ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print(path)
