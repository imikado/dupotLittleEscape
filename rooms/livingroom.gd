extends Node3D

signal gotoChessBoardZoom
signal gotoRemoteControlZoom

var room="livingRoom"


func _ready():
	
	$tableCoffee/remoteControl.init(room,"remoteControl")
	
	$tableCoffee/chess_board.init(room,"chessBoard")
	
	$cabinetTelevision/television.init(room,"tv")
	
	$tableCloth.init(room,"secretBox")
	
	$laptop.init(room,"laptop")


func _on_chess_board_gotoChessBoardZoom():
	emit_signal("gotoChessBoardZoom")



func _on_remoteControl_gotoRemoteControlZoom():
	emit_signal("gotoRemoteControlZoom")
