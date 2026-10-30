extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
const LANGUAGE_NAMES={"fr":"Français","en":"English"}
#the title floats gently
const FLOAT_HEIGHT=6.0
const FLOAT_DURATION=1.2
#keys not remappable, shown after the game actions
const FIXED_KEYS=[{"name":"KEYS_PAUSE","key":"KEY_ESCAPE"},{"name":"KEYS_FULLSCREEN","key":"F11"}]

func _ready():
	%version.text="v"+str(ProjectSettings.get_setting("application/config/version"))

	var languageButton=%language
	for language in GlobalGame.LANGUAGES:
		languageButton.add_item(LANGUAGE_NAMES[language])
		languageButton.set_item_metadata(languageButton.item_count-1,language)
		if language==GlobalGame.getLanguage():
			languageButton.select(languageButton.item_count-1)

	refreshKeyboard()
	GlobalInput.keysChanged.connect(refreshKeyboard)

	#keyboard / gamepad: Enter starts directly
	%play.grab_focus.call_deferred()
	floatTitle()

func floatTitle():
	var start=%title.position.y
	var tween=create_tween().set_loops()
	tween.tween_property(%title,"position:y",start-FLOAT_HEIGHT,FLOAT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(%title,"position:y",start,FLOAT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

#keyboard keys reminder: a keycap and the action for each line
func refreshKeyboard():
	var grid=%keys
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for item in GlobalInput.ACTIONS:
		addKeyLine(grid,GlobalInput.getActionKeysName(item.action),item.name)
	for item in FIXED_KEYS:
		addKeyLine(grid,tr(item.key),item.name)

func addKeyLine(grid_,keys_,name_):
	var keycap=PanelContainer.new()
	keycap.size_flags_horizontal=Control.SIZE_SHRINK_END
	keycap.add_theme_stylebox_override("panel",getKeycapStyle())
	var keyLabel=Label.new()
	keyLabel.text=keys_
	keyLabel.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	keyLabel.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	keyLabel.add_theme_font_size_override("font_size",14)
	keycap.add_child(keyLabel)
	grid_.add_child(keycap)

	var nameLabel=Label.new()
	nameLabel.text=name_
	nameLabel.add_theme_font_size_override("font_size",15)
	grid_.add_child(nameLabel)

var keycapStyle=null

func getKeycapStyle():
	if keycapStyle==null:
		keycapStyle=StyleBoxFlat.new()
		keycapStyle.bg_color=Color(1,1,1,1)
		keycapStyle.border_color=Color(0.45,0.26,0.62,1)
		keycapStyle.set_border_width_all(2)
		keycapStyle.border_width_bottom=4
		keycapStyle.set_corner_radius_all(6)
		keycapStyle.content_margin_left=8
		keycapStyle.content_margin_right=8
		keycapStyle.content_margin_top=1
		keycapStyle.content_margin_bottom=1
	return keycapStyle

func _on_language_item_selected(index_):
	GlobalGame.setLanguage(%language.get_item_metadata(index_))
	#key names are translated when the lines are built
	refreshKeyboard()

func _on_settings_pressed():
	%windows.visible=false
	%title.visible=false
	%keySettings.open()

func _on_key_settings_closed():
	%windows.visible=true
	%title.visible=true
	%settings.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_CheckButton_toggled(button_pressed):
	GlobalGame.setVrEnabled(button_pressed)
	pass # Replace with function body.


func _on_play_pressed():
	SceneTransition.changeScene("res://flat.tscn")
	pass # Replace with function body.


func _on_gamepadEnabled_toggled(button_pressed):
	GlobalGame.setGamepadEnabled(button_pressed)
	
	#touch controls: the keyboard keys are not needed
	%blocKeyboard.visible=!button_pressed
	pass # Replace with function body.
