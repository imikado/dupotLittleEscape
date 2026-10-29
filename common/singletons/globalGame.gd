extends Node

var vrEnabled=true
var gamepadEnabled=false

func setVrEnabled(bool_):
	vrEnabled=bool_
	
func isVRenabled():
	return vrEnabled

func setGamepadEnabled(bool_):
	gamepadEnabled=bool_

func isGamepadEnabled():
	return gamepadEnabled

const SETTINGS_FILE="user://settings.cfg"
const LANGUAGES=["fr","en"]

func setLanguage(language_):
	if !LANGUAGES.has(language_):
		language_="en"
	TranslationServer.set_locale(language_)

	var settings=ConfigFile.new()
	settings.load(SETTINGS_FILE)
	settings.set_value("game","language",language_)
	settings.save(SETTINGS_FILE)

func getLanguage():
	return TranslationServer.get_locale().substr(0,2)

func loadLanguage():
	var settings=ConfigFile.new()
	settings.load(SETTINGS_FILE)
	#first launch: use the system language
	var language=settings.get_value("game","language",OS.get_locale_language())
	if !LANGUAGES.has(language):
		language="en"
	TranslationServer.set_locale(language)


func _ready():
	loadLanguage()

func isFullscreen():
	return DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN

func toggleFullscreen():
	if isFullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		#started in fullscreen: the window keeps the screen size, back to the default size
		if !OS.has_feature("web"):
			var size=Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),ProjectSettings.get_setting("display/window/size/viewport_height"))
			DisplayServer.window_set_size(size)
			var screen=DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
			DisplayServer.window_set_position(screen.position+(screen.size-size)/2)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

#F11: switch between fullscreen and windowed
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and !event.echo and event.keycode==KEY_F11:
		toggleFullscreen()

func initCamera(arvrOrigin_,vectorNonVr_):
	return
	var vr_interface=XRServer.find_interface("Native mobile")
	if vr_interface and vr_interface.initialize():
			get_viewport().use_xr=isVRenabled()

	if !isVRenabled():
		pass
		arvrOrigin_.global_translate(vectorNonVr_)
