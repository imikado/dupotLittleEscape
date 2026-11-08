extends StaticBody3D

var inverted=false

var defaultProps={}
var props={}

var infoPanel=null


enum {OPENED,CLOSED}

#the key unlocks the door, then the door opens by itself: time to see the key turn
const UNLOCK_OPEN_DELAY=0.9

#no action while the door is being unlocked
var busy=false

var item=null
var scene=null
var object=null

func init(scene_,object_,inverted_,key_=null):
	scene=scene_
	object=object_

	inverted=inverted_
	
	defaultProps.key=key_

	defaultProps.locked=false

	if key_!=null:
		defaultProps.locked=true

	props=GlobalRoom.getStateForRoomOr(scene,object,defaultProps)

	if inverted==true:
		infoPanel=$info2
		$info.visible=false
	else:
		infoPanel=$info
		$info2.visible=false

	hideInfo()
		
	refreshState()

func hasKey():
	if GlobalPlayer.hasItem(props.key):
		return true
	else:
		return false

func saveProps():
	GlobalRoom.saveStateForObject(scene,object,props)

func setKey(key_):
	props.key=key_

func showInfo(text_):
	if getInfoPanel():
		getInfoPanel().showInfo(text_)

func hideInfo():
	if getInfoPanel():
		getInfoPanel().hideInfo()

func getInfoPanel():
	return infoPanel

#the object the player is looking at
func setTargeted(targeted_):
	ToonStyle.setHighlighted(self,targeted_)

func action():
	if busy:
		return
	hideInfo()
	if props.state==CLOSED:
		if props.locked:
			if hasKey():
				unlock()
			else:
				GlobalAudio.play("locked")
				showInfo("INFO_DOOR_LOCKED")
		else:
			openDoor()
	else:
		closeDoor()

#one action: the key unlocks the door ("used" popup), then the door opens
func unlock():
	props.locked=false
	saveProps()

	GlobalAudio.play("unlock")
	GlobalPlayer.useItem(props.key)
	showInfo("INFO_DOOR_UNLOCKED")

	busy=true
	#bound to the door: nothing happens if the scene changes meanwhile
	var tween=create_tween()
	tween.tween_interval(UNLOCK_OPEN_DELAY)
	tween.tween_callback(openUnlocked)

func openUnlocked():
	busy=false
	openDoor()

func displayInfo():
	#to be implemented in child class
	pass

#animated, saves the state: to be implemented in child class
func openDoor():
	pass

func closeDoor():
	pass

func refreshState():
	#to be implemented in child class
	pass
