extends CanvasLayer

#scenes without pause menu
const DISABLED_SCENES=["res://ui/boot.tscn"]
#scenes where "main menu" makes no sense
const NO_MAIN_MENU_SCENES=["res://ui/Menu.tscn"]
#scenes without HUD (menu button)
const NO_HUD_SCENES=["res://ui/boot.tscn","res://ui/Menu.tscn","res://ui/end.tscn"]

#close-up scenes: back to the room + controls reminder
const ZOOM_HINTS={
	"res://zooms/bedroom_closet.tscn":"ZOOM_HINT_CODE",
	"res://zooms/bathroom_secretBox.tscn":"ZOOM_HINT_CODE",
	"res://zooms/kitchen_secretBox.tscn":"ZOOM_HINT_CODE",
	"res://zooms/livingroom_remoteControl.tscn":"ZOOM_HINT_REMOTE",
	"res://zooms/livingroom_chessBoard.tscn":"ZOOM_HINT_CHESS",
}

#delay before the game gets the inputs back (avoid triggering an action with Enter)
const RESUME_DELAY=0.1

@onready var overlay=$overlay
@onready var hud=$hud

func _ready():
	overlay.visible=false
	#a browser tab cannot be closed by the game
	if OS.has_feature("web"):
		$overlay/window/content/quit.visible=false
		$overlay/window/content/resume.focus_neighbor_top=$overlay/window/content/mainMenu.get_path()
	refreshFullscreenButton()

func _process(_delta):
	var scenePath=getCurrentScenePath()
	hud.visible=!NO_HUD_SCENES.has(scenePath) and !get_tree().paused

	var isZoom=ZOOM_HINTS.has(scenePath)
	$hud/box/buttons/back.visible=isZoom
	$hud/box/hint.visible=isZoom
	if isZoom:
		$hud/box/hint.text=ZOOM_HINTS[scenePath]

func isOpen():
	return overlay.visible

func getCurrentScenePath():
	var scene=get_tree().current_scene
	return scene.scene_file_path if scene else ""

func open():
	var scenePath=getCurrentScenePath()
	if DISABLED_SCENES.has(scenePath):
		return
	$overlay/window/content/mainMenu.visible=!NO_MAIN_MENU_SCENES.has(scenePath)
	refreshFullscreenButton()
	overlay.visible=true
	get_tree().paused=true
	$overlay/window/content/resume.grab_focus.call_deferred()

func close():
	overlay.visible=false
	await get_tree().create_timer(RESUME_DELAY,true).timeout
	if !overlay.visible:
		get_tree().paused=false

func refreshFullscreenButton():
	$overlay/window/content/fullscreen.text="PAUSE_FULLSCREEN_ON" if GlobalGame.isFullscreen() else "PAUSE_FULLSCREEN_OFF"

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode==KEY_ESCAPE:
			if isOpen():
				close()
			else:
				open()
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_F11:
			#GlobalGame switches the mode, refresh once it is done
			refreshFullscreenButton.call_deferred()

func _on_resume_pressed():
	close()

func _on_fullscreen_pressed():
	GlobalGame.toggleFullscreen()
	refreshFullscreenButton()

func _on_main_menu_pressed():
	overlay.visible=false
	get_tree().paused=false
	get_tree().change_scene_to_file("res://ui/Menu.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_menu_button_pressed():
	open()

func _on_back_pressed():
	var scene=get_tree().current_scene
	if scene and scene.has_method("pushButtonB"):
		scene.pushButtonB()
	else:
		get_tree().change_scene_to_file("res://flat.tscn")
