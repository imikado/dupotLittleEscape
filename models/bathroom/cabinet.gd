extends "res://common/abstracts/furniture.gd"

signal openHotWater
signal closeHotWater

func _ready():
	defaultProps={
		"state":CLOSED
	}
	
func refreshState():
	if props.state==OPENED:
		openTap(false)
		
		
func openTap(animated_=true):
	if animated_:
		GlobalAudio.play("water")
	emit_signal("openHotWater")
	
func closeTap():
	emit_signal("closeHotWater")
	
func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_HOT_WATER_OPEN")
	else:
		showInfo("INFO_HOT_WATER_CLOSE")


func action():
	if props.state==CLOSED:
		openTap()
		
		props.state=OPENED
	else:
		closeTap()
		
		props.state=CLOSED
	
	saveProps()
		
	displayInfo()
