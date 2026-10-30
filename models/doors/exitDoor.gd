extends "res://common/abstracts/door.gd"

signal exitDoorOpened

func _ready():
	defaultProps={
		"state":CLOSED
	}
	
func refreshState():
	if props.state==OPENED:
		openDoor(false)
	
func openDoor(animated_=true):
	$door.open(animated_)

func closeDoor():
	$door.close()
	

func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_OPEN_IT")
	else:
		showInfo("INFO_CLOSE_IT")


func action():
	hideInfo()
	if props.state==CLOSED:
		if props.locked:
			
			if hasKey():
				props.locked=false
				saveProps()
				
				GlobalAudio.play("unlock")
				GlobalPlayer.useItem(props.key)
				showInfo("INFO_DOOR_UNLOCKED")
			else:
				GlobalAudio.play("locked")
				showInfo("INFO_DOOR_LOCKED")
		else:
			openDoor()
			
			props.state=OPENED
			
			emit_signal("exitDoorOpened")
			
	else:
		closeDoor()
		
		props.state=CLOSED
	
	saveProps()
		

