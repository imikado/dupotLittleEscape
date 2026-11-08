extends Node3D

var room="flat"

# Called when the node enters the scene tree for the first time.
func _ready():
	if GlobalPlayer.shouldLoadPosition():
		$Player.global_transform.origin=GlobalPlayer.getPosition()
		
		$Player.loadCameraPosition(GlobalPlayer.getCameraPosition())
		#teleport: no interpolation from the start position
		$Player.reset_physics_interpolation()
	
	
	$doors/bedroom/door.init(room,"bedroom_door",true,GlobalItems.ID.BEDROOM_KEY)
	
	$doors/bathroom/door.init(room,"bathroom_door",false,GlobalItems.ID.BATHROOM_KEY)
	
	$doors/kitchen/door.init(room,"kitchen_door",true,GlobalItems.ID.KITCHEN_KEY)
	
	$doors/exit/exitDoor.init(room,"exit_door",false,GlobalItems.ID.EXIT_KEY)


func _on_Player_gotoInventory():
	$inventoryPanel.toggle()


#close-ups: the flat stays in memory, it is not reloaded when the player comes back
func gotoZoom(path_):
	savePlayerPosition()
	SceneTransition.changeScene(path_,0.0,true)

func _on_bedroom_gotoClosetZoom():
	gotoZoom("res://zooms/bedroom_closet.tscn")

#also read by "continue" in the main menu, and written to the save
func savePlayerPosition():
	GlobalPlayer.savePosition($Player.global_transform.origin)
	GlobalPlayer.saveCameraPosition($Player.getCameraPosition())
	GlobalPlayer.saveGame()

func _on_livingroom_gotoChessBoardZoom():
	gotoZoom("res://zooms/livingroom_chessBoard.tscn")

func _on_livingroom_gotoRemoteControlZoom():
	gotoZoom("res://zooms/livingroom_remoteControl.tscn")

func _on_bathroom_gotoBathroomSecretBoxZoom():
	gotoZoom("res://zooms/bathroom_secretBox.tscn")

func _on_kitchen_gotoKitchenSecretBoxZoom():
	gotoZoom("res://zooms/kitchen_secretBox.tscn")

#back from a close-up (SceneTransition): _ready is not called again
func onRestored():
	#the close-ups save the state of their own copy of these objects
	reloadState($rooms/bedroom/closet)
	reloadState($rooms/bathroom/secretBoxWithCode)
	reloadState($rooms/kitchen/cabinetDrawer2/secretBoxWithCode)
	reloadState($rooms/livingroom/cabinetTelevision/television)

	#the object in reach shows its (maybe new) info again
	var nearObject=$Player.nearObject
	if is_instance_valid(nearObject):
		if nearObject.has_method("hideInfo"):
			nearObject.hideInfo()
		if nearObject.has_method("setTargeted"):
			nearObject.setTargeted(false)
	$Player.nearObject=null
	$Player.reset_physics_interpolation()

func reloadState(object_):
	object_.props=GlobalRoom.getStateForRoomOr(object_.scene,object_.object,object_.props)
	if object_.has_method("refreshItem"):
		object_.refreshItem()
	object_.refreshState()


#time to see the exit door open before the end screen
const EXIT_DELAY=0.7

func _on_exitDoor_exitDoorOpened():
	SceneTransition.changeScene("res://ui/end.tscn",EXIT_DELAY)
