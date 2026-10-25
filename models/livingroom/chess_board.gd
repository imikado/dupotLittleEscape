extends "res://common/abstracts/furniture.gd"

signal gotoChessBoardZoom


func _ready():
	defaultProps={
		"state":CLOSED,
	}



func displayInfo():
	showInfo("INFO_SEE_CHESS")

func disableInfo():
	$info.visible=false

func action():
	
	emit_signal("gotoChessBoardZoom")
	#saveProps()
		
	displayInfo()	
