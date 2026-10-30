extends "res://common/abstracts/furniture.gd"


signal gotoClosetZoom

func _ready():
	defaultProps={
		"state":CLOSED,
		"locked":true
	}
	
func zoom():
	$info.visible=false
	
func goUp():
	$doorLeft/padlock.goUp()

func goDown():
	$doorLeft/padlock.goDown()

func goLeft():
	$doorLeft/padlock.goLeft()

func goRight():
	$doorLeft/padlock.goRight()
	
func isSecretCode():
	return $doorLeft/padlock.isCodeCorrect()

func unlock():
	props.locked=false
	$doorLeft/padlock.open()
	GlobalAudio.play("unlock")
	saveProps()
	
func isLocked():
	return props.locked

	
func refreshState():
	if props.state==OPENED:
		openDoors(false)
	if props.locked==false:
		$doorLeft/padlock.open(false)
		
func refreshItem():
	$bedroom_key.visible=false
	
	if props.item==GlobalItems.ID.BEDROOM_KEY:
		$bedroom_key.visible=true
		
func openDoors(animated_=true):
	$doorLeft.open(animated_)
	$doorRight.open(animated_)

func closeDoors():
	$doorLeft.close()
	$doorRight.close()


func displayInfo():

	if props.state==CLOSED:
		showInfo("INFO_OPEN_IT")
	else:
		if props.item==GlobalItems.ID.BEDROOM_KEY:
			showInfo("INFO_TAKE_KEY")
		else:
			showInfo("INFO_CLOSE_IT")


func action():
	if props.state==CLOSED:
		
		if props.locked:
			
			emit_signal("gotoClosetZoom")
		else:
			openDoors()
			
			props.state=OPENED
	else:
		closeDoors()
		
		props.state=CLOSED
	
	saveProps()
		
	displayInfo()
