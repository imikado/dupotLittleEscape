extends Node3D

var room="flat"

func debug():
	GlobalPlayer.addItem(GlobalItems.ID.EXIT_KEY)


# Called when the node enters the scene tree for the first time.
func _ready():
	
	#debug()
	#GlobalPlayer.addItem(GlobalItems.ID.EXIT_KEY)
	
	if GlobalPlayer.shouldLoadPosition():
		$Player.global_transform.origin=GlobalPlayer.getPosition()
		
		$Player.loadCameraPosition(GlobalPlayer.getCameraPosition())
	
	$sky.visible=true
	
	$doors/bedroom/door.init(room,"bedroom_door",true,GlobalItems.ID.BEDROOM_KEY)
	
	$doors/bathroom/door.init(room,"bathroom_door",false,GlobalItems.ID.BATHROOM_KEY)
	
	$doors/kitchen/door.init(room,"kitchen_door",true,GlobalItems.ID.KITCHEN_KEY)
	
	$doors/exit/exitDoor.init(room,"exit_door",false,GlobalItems.ID.EXIT_KEY)


func _on_Player_gotoInventory():
	$inventoryPanel.toggle()


func _on_bedroom_gotoClosetZoom():
	savePlayerPosition()
	get_tree().change_scene_to_file("res://zooms/bedroom_closet.tscn")

func savePlayerPosition():
	GlobalPlayer.savePosition($Player.global_transform.origin)
	GlobalPlayer.saveCameraPosition($Player.getCameraPosition())


func _on_livingroom_gotoChessBoardZoom():
	savePlayerPosition()
	get_tree().change_scene_to_file("res://zooms/livingroom_chessBoard.tscn")


func _on_livingroom_gotoRemoteControlZoom():
	savePlayerPosition()
	get_tree().change_scene_to_file("res://zooms/livingroom_remoteControl.tscn")
	pass # Replace with function body.


func _on_bathroom_gotoBathroomSecretBoxZoom():
	savePlayerPosition()
	get_tree().change_scene_to_file("res://zooms/bathroom_secretBox.tscn")
	pass # Replace with function body.


func _on_kitchen_gotoKitchenSecretBoxZoom():
	savePlayerPosition()
	get_tree().change_scene_to_file("res://zooms/kitchen_secretBox.tscn")
	pass # Replace with function body.


func _on_exitDoor_exitDoorOpened():
	get_tree().change_scene_to_file("res://ui/end.tscn")
	pass # Replace with function body.
