extends "res://tools/capture/capture.gd"
# Génère uniquement les screenshots (voir tools/capture/screenshots.sh), sans
# enregistrer toute la visite : chaque plan de capture.gd est chargé seul et
# l'image est prise aux 2/3 du plan, comme dans capture.sh.
#
# Lancé avec --fixed-fps 30 : le temps est fixe, les images sont identiques à
# celles de la visite.

const FPS=30
const DEFAULT_SHOTS="menu bedroom bathroom livingroom kitchen chessboard"
const DEFAULT_DIR="res://export/Linux/screenshots"

func _initialize():
	_run()

# remplace la visite guidée de capture.gd
func _process(_delta):
	return false

func _run():
	var names=OS.get_environment("SCREENSHOTS_SHOTS")
	if names=="":
		names=DEFAULT_SHOTS
	var dir=OS.get_environment("SCREENSHOTS_DIR")
	if dir=="":
		dir=ProjectSettings.globalize_path(DEFAULT_DIR)
	DirAccess.make_dir_recursive_absolute(dir)

	# attend le _ready des singletons (GlobalGame recharge la langue)
	await process_frame
	TranslationServer.set_locale("en")

	for name in names.split(" ",false):
		var shot=_find_shot(name)
		if shot==null:
			printerr("Plan inconnu : %s"%name)
			quit(1)
			return
		change_scene_to_file(shot.scene)
		await scene_changed
		# même instant que capture.sh : aux 2/3 du plan
		var t=2.0/3.0
		var frames=int(shot.duration*FPS*t)
		for i in frames:
			if shot.has("from"):
				_place_camera(shot,smoothstep(0.0,1.0,i/(shot.duration*FPS)))
			await process_frame
		await RenderingServer.frame_post_draw
		var path=dir.path_join(name+".png")
		root.get_texture().get_image().save_png(path)
		print(path)
	quit()
