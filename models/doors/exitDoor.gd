extends "res://common/abstracts/door.gd"

signal exitDoorOpened

func _ready():
	defaultProps={
		"state":CLOSED
	}

func refreshState():
	if props.state==OPENED:
		$door.open(false)

func openDoor():
	$door.open()

	props.state=OPENED
	saveProps()

	emit_signal("exitDoorOpened")

func closeDoor():
	$door.close()

	props.state=CLOSED
	saveProps()


func displayInfo():
	#opened: the game ends, nothing to do anymore
	if props.state==CLOSED:
		showInfo("INFO_OPEN_IT")


func action():
	#opened: the end screen is coming, the door stays open
	if props.state==OPENED:
		return
	super.action()
