extends Node3D


var room='kitchen'

signal gotoKitchenSecretBoxZoom


func _ready():
	
	$cabinetDrawer2/secretBoxWithCode.init(room,"secretBox",GlobalItems.ID.EXIT_KEY)


func _on_secretBoxWithCode_gotoSecretBoxZoom():
	emit_signal("gotoKitchenSecretBoxZoom")
