extends "res://common/abstracts/furniture.gd"


func _ready():
	defaultProps={
		"state":CLOSED
	}
	
func refreshState():
	if props.state==OPENED:
		switchOnScreen()
		
func resetScreens():
	$screenOff.visible=false
	$screenOn.visible=false

func switchOnScreen():
	resetScreens()
	$screenOn.visible=true
	
func switchOffScreen():
	resetScreens()
	$screenOff.visible=true
	
func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_LAPTOP_ON")
	else:
		showInfo("INFO_LAPTOP_OFF")


func action():
	GlobalAudio.play("switch")
	if props.state==CLOSED:
		switchOnScreen()
		
		props.state=OPENED
	else:
		switchOffScreen()
		
		props.state=CLOSED
	
	saveProps()
		
	displayInfo()
