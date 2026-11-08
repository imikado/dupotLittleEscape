extends "res://common/abstracts/furniture.gd"

#animated_ false: state restored when the scene is loaded (the steam is already on the mirror)
signal openHotWater(animated_)
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
	openHotWater.emit(animated_)
	
func closeTap():
	closeHotWater.emit()
	
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
