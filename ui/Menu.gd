extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
const LANGUAGE_NAMES={"fr":"Français","en":"English"}

func _ready():
	var languageButton=$languageBloc/language
	for language in GlobalGame.LANGUAGES:
		languageButton.add_item(LANGUAGE_NAMES[language])
		languageButton.set_item_metadata(languageButton.item_count-1,language)
		if language==GlobalGame.getLanguage():
			languageButton.select(languageButton.item_count-1)

func _on_language_item_selected(index_):
	GlobalGame.setLanguage($languageBloc/language.get_item_metadata(index_))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_CheckButton_toggled(button_pressed):
	GlobalGame.setVrEnabled(button_pressed)
	pass # Replace with function body.


func _on_play_pressed():
	get_tree().change_scene_to_file("res://flat.tscn")
	pass # Replace with function body.


func _on_gamepadEnabled_toggled(button_pressed):
	GlobalGame.setGamepadEnabled(button_pressed)
	
	if button_pressed:
		$blocGamepad.visible=false
	else:
		$blocGamepad.visible=true
	pass # Replace with function body.
