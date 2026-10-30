extends "res://common/abstracts/door.gd"



func _ready():
	defaultProps={
		"state":CLOSED
	}
	
func refreshState():
	if props.state==OPENED:
		$door.openDirection=props.get("direction",1.0)
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
			#pushed: the door opens away from the player
			props.direction=$door.getAwayDirection(get_viewport().get_camera_3d().global_position)
			$door.openDirection=props.direction
			openDoor()
			
			props.state=OPENED
	else:
		closeDoor()
		
		props.state=CLOSED
	
	saveProps()
		

