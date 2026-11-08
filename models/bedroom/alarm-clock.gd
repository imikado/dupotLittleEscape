extends MeshInstance3D

#the colon blinks every half second, like a real alarm clock: hidden (transparent) rather than
#removed so the digits do not move
var colonVisible=true

func refreshTime():
	var datetimeNow= Time.get_datetime_dict_from_system()
	
	var colon=":" if colonVisible else "[color=#0000]:[/color]"
	var timeString="%02d%s%02d"%[datetimeNow.hour,colon,datetimeNow.minute]
	
	$SubViewport/Panel/Label.text="[center]"+timeString+"[/center]"
	$SubViewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	

func _ready():
	refreshTime()
	$Timer.start()


func _on_Timer_timeout():
	colonVisible=!colonVisible
	refreshTime()
