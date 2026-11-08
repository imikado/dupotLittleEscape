extends "res://common/abstracts/furniture.gd"

const CodeWheels=preload("res://common/abstracts/codeWheels.gd")

@export var rightCode=[0,0,0,0] # (Array,int)

var wheels=CodeWheels.new(self,"cover/bloc","SubViewport")

signal gotoSecretBoxZoom

func disableInfo():
	$info.visible=false

func _ready():
	defaultProps={
		"state":CLOSED,
		"locked":true
	}
	wheels.reset()

#close-up: the selected wheel is highlighted (not in the room)
func startEditing():
	wheels.startEditing()

func goDown():
	wheels.goDown()

func goUp():
	wheels.goUp()

func goLeft():
	wheels.goLeft()

func goRight():
	wheels.goRight()

func isCodeCorrect():
	return wheels.isCodeCorrect(rightCode)

func refreshState():
	if props.state==OPENED:
		openCover(false)
		
	if !props.locked:
		for i in range(0,4):
			wheels.setLine(i+1, str(rightCode[i]) )
		
func refreshItem():
	$base/kitchen_key.visible=false
	$base/exit_key.visible=false
	
	if props.item==GlobalItems.ID.KITCHEN_KEY:
		$base/kitchen_key.visible=true
		
	if props.item==GlobalItems.ID.EXIT_KEY:
		$base/exit_key.visible=true
		
func openCover(animated_=true):
	$cover.open(animated_)

func closeCover():
	$cover.close()

func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_OPEN_IT")
	else:
		if props.item!=null:
			showInfo("INFO_TAKE_KEY")
		else:
			showInfo("INFO_CLOSE_IT")


func action():
	if props.state==CLOSED:
		if props.locked:
			
			emit_signal("gotoSecretBoxZoom")
			
			#showInfo("Elle semble fermé")
			return
		
		openCover()
		
		props.state=OPENED
	else:
		closeCover()
		
		props.state=CLOSED
	
	saveProps()
		
	displayInfo()
	

func unlock():
	props.state=OPENED
	props.locked=false
	wheels.unselectAll()
	openCover()
	saveProps()
	
func isLocked():
	return props.locked

