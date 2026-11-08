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
	#wheels side by side
	"res://zooms/bathroom_secretBox.tscn":"ZOOM_HINT_BOX",
	"res://zooms/kitchen_secretBox.tscn":"ZOOM_HINT_BOX",
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
	#the hint texts change with the scene, the keys and the language (NOTIFICATION_TRANSLATION_CHANGED)
	get_tree().scene_changed.connect(refreshHud)
	GlobalInput.keysChanged.connect(refreshHud)
	refreshHud.call_deferred()

func _notification(what_):
	if what_==NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refreshHud()

func _process(_delta):
	hud.visible=!NO_HUD_SCENES.has(getCurrentScenePath()) and !get_tree().paused

func refreshHud():
	var scenePath=getCurrentScenePath()
	var isZoom=ZOOM_HINTS.has(scenePath)
	$hud/box/buttons/back.visible=isZoom
	$hud/box/hint.visible=isZoom
	if isZoom:
		$hud/box/hint.text=GlobalInput.formatText(ZOOM_HINTS[scenePath])
		$hud/box/buttons/back.text=GlobalInput.formatText("ZOOM_BACK")

func isOpen():
	return overlay.visible

func getCurrentScenePath():
	var scene=get_tree().current_scene
	return scene.scene_file_path if scene else ""

func open():
	var scenePath=getCurrentScenePath()
	if DISABLED_SCENES.has(scenePath):
		return
	#already paused by the inventory: closing the menu would unpause the game behind it
	#scene change in progress: the menu would stay open over the next scene
	if get_tree().paused or SceneTransition.isBusy():
		return
	$overlay/window/content/mainMenu.visible=!NO_MAIN_MENU_SCENES.has(scenePath)
	refreshFullscreenButton()
	refreshSoundButton()
	$overlay/window/content/controls.text=GlobalInput.formatText("PAUSE_CONTROLS")
	GlobalAudio.play("pop")
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

func refreshSoundButton():
	$overlay/window/content/sound.text="PAUSE_SOUND_ON" if GlobalAudio.isEnabled() else "PAUSE_SOUND_OFF"

func _unhandled_input(event):
	#gamepad: Start opens and closes the pause menu, like Escape
	if event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START:
		togglePause()
		return
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode==KEY_ESCAPE:
			togglePause()
		elif event.keycode==KEY_F11:
			#GlobalGame switches the mode, refresh once it is done
			refreshFullscreenButton.call_deferred()

func togglePause():
	if isOpen():
		close()
	else:
		open()
	get_viewport().set_input_as_handled()

func _on_resume_pressed():
	close()

func _on_fullscreen_pressed():
	GlobalGame.toggleFullscreen()
	refreshFullscreenButton()

func _on_sound_pressed():
	GlobalAudio.toggle()
	refreshSoundButton()

func _on_main_menu_pressed():
	#"continue" in the main menu starts again from here
	var scene=get_tree().current_scene
	if scene and scene.has_method("savePlayerPosition"):
		scene.savePlayerPosition()
	overlay.visible=false
	get_tree().paused=false
	SceneTransition.changeScene("res://ui/Menu.tscn")

func _on_quit_pressed():
	#"continue" at the next launch starts again from here
	GlobalPlayer.saveCurrentScene()
	get_tree().quit()

func _on_menu_button_pressed():
	open()

func _on_back_pressed():
	var scene=get_tree().current_scene
	if scene and scene.has_method("pushButtonB"):
		scene.pushButtonB()
	else:
		SceneTransition.changeScene("res://flat.tscn")
