extends Node3D

@export var text: String
@export var hasBackground: bool=false


func _ready():
	init(text)
	
	if hasBackground:
		$background.visible=true

func init(text_):
	$MeshInstance3D/SubViewport/Label.text=text_
	#static text: render the viewport only when it changes
	$MeshInstance3D/SubViewport.render_target_update_mode=SubViewport.UPDATE_ONCE
