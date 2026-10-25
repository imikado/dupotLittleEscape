extends MeshInstance3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func refreshTime():
	var datetimeNow= Time.get_datetime_dict_from_system()
	
	var timeString=str("%02d"%[datetimeNow.hour])+":"+str("%02d"%[datetimeNow.minute])
	
	$SubViewport/Panel/Label.text=timeString
	$SubViewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	
	refreshTime()
	
	$Timer.start()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	refreshTime()

