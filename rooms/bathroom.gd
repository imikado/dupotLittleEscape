extends Node3D

var room='bathroom'

signal gotoBathroomSecretBoxZoom


func _ready():
	
	$cabinet.init(room,"cabinet")
	
	$secretBoxWithCode.init(room,"secretBoxWithCode",GlobalItems.ID.KITCHEN_KEY)


#animated_ false: state restored when the scene is loaded
func _on_cabinet_openHotWater(animated_):
	$mirror.showHotWater(animated_)
	$tapWater.showWater(animated_)


func _on_cabinet_closeHotWater():
	$mirror.hideHotWater()
	$tapWater.hideWater()



func _on_secretBoxWithCode_gotoSecretBoxZoom():
	emit_signal("gotoBathroomSecretBoxZoom")
