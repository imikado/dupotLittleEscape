extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var vr_interface=ARVRServer.find_interface("Native mobile")
	if vr_interface and vr_interface.initialize():
			get_viewport().arvr=false
			get_viewport().hdr=false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	print("go back menu")
	get_tree().change_scene("res://ui/Menu.tscn")
	pass # Replace with function body.
