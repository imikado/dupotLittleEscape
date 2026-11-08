extends Node

const Settings=preload("res://common/singletons/settings.gd")

var gamepadEnabled=false

#touch controls (joystick and buttons on the screen), saved in the settings file
func setGamepadEnabled(bool_):
	gamepadEnabled=bool_
	Settings.setValue("game","touch",gamepadEnabled)

func isGamepadEnabled():
	return gamepadEnabled

#first launch: on if the device has a touchscreen (phone, tablet), not on a desktop build (laptops
#with a touchscreen have a keyboard)
func loadGamepadEnabled():
	var touch=DisplayServer.is_touchscreen_available() and (OS.has_feature("mobile") or OS.has_feature("web"))
	gamepadEnabled=Settings.getValue("game","touch",touch)

const LANGUAGES=["fr","en"]

func setLanguage(language_):
	if !LANGUAGES.has(language_):
		language_="en"
	TranslationServer.set_locale(language_)
	Settings.setValue("game","language",language_)

func getLanguage():
	return TranslationServer.get_locale().substr(0,2)

func loadLanguage():
	#first launch: use the system language
	var language=Settings.getValue("game","language",OS.get_locale_language())
	if !LANGUAGES.has(language):
		language="en"
	TranslationServer.set_locale(language)


func _ready():
	loadLanguage()
	loadGamepadEnabled()

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
