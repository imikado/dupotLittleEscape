extends Node3D

@export var text: String
@export var hasBackground: bool=false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$MeshInstance3D/SubViewport/Label.text=text
	
	if hasBackground:
		$background.visible=true
	pass # Replace with function body.

func init(text_):
	$MeshInstance3D/SubViewport/Label.text=text_

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
