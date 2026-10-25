extends SceneTree
# Génère les icônes PNG de l'appdata Flathub (export/Linux/flatpak/icons/) à
# partir de tools/icons/icon.svg.
#
# Usage : godot --headless --path . -s tools/icons/generate_icons.gd

const SOURCE="res://tools/icons/icon.svg"
const OUTPUT_DIR="res://export/Linux/flatpak/icons"
const SIZES=[16,24,32,48,64,128,256,512]

func _initialize():
	# tools/ et export/ sont ignorés par Godot (.gdignore) : lecture directe des fichiers
	var svg=FileAccess.get_file_as_string(ProjectSettings.globalize_path(SOURCE))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for size in SIZES:
		var image=Image.new()
		# rendu vectoriel à la taille finale (net même en 512)
		image.load_svg_from_string(svg,size/256.0)
		var path=ProjectSettings.globalize_path("%s/%dx%d.png"%[OUTPUT_DIR,size,size])
		image.save_png(path)
		print(path)
	quit()
