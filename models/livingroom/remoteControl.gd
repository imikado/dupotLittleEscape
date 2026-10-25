extends "res://common/abstracts/furniture.gd"

signal gotoRemoteControlZoom


func _ready():
	defaultProps={
		"state":CLOSED
	}



func displayInfo():
	showInfo("INFO_SEE_REMOTE")


func action():
	
	emit_signal("gotoRemoteControlZoom")
	#saveProps()
		
	displayInfo()	
