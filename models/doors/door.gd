extends "res://common/abstracts/door.gd"



func _ready():
	defaultProps={
		"state":CLOSED
	}

func refreshState():
	if props.state==OPENED:
		$door.openDirection=props.get("direction",1.0)
		$door.open(false)

#pushed: the door opens away from the player
func openDoor():
	props.direction=$door.getAwayDirection(get_viewport().get_camera_3d().global_position)
	$door.openDirection=props.direction
	$door.open()

	props.state=OPENED
	saveProps()

func closeDoor():
	$door.close()

	props.state=CLOSED
	saveProps()


func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_OPEN_IT")
	else:
		showInfo("INFO_CLOSE_IT")
