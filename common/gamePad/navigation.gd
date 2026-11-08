extends CanvasLayer

signal movePlayer(joystickVector_)

signal pushButtonA
signal pushButtonB

signal navLeft
signal navRight
signal navUp
signal navDown

var _isEnable=true

@export var displayLeftNav: bool=false
@export var displayLeftJoystick: bool=false

@export var displayButtonA: bool=false
@export var displayButtonB: bool=false

func _ready():
	if GlobalGame.isGamepadEnabled():
		enable()
	else:
		disable()

func enable():
	_isEnable=true
	$buttonA.visible=displayButtonA
	$buttonB.visible=displayButtonB
	$"joystick-big".visible=displayLeftJoystick
	$nav.visible=displayLeftNav

func disable():
	_isEnable=false
	$buttonA.visible=false
	$buttonB.visible=false
	$"joystick-big".visible=false
	$nav.visible=false

func _on_joystickbig_moveJoystick(joystickVector_):
	if _isEnable:
		emit_signal("movePlayer",joystickVector_)

func _on_buttonB_pushButton():
	emit_signal("pushButtonB")


func _on_buttonA_pushButton():
	emit_signal("pushButtonA")


func _on_down_pushButton():
	emit_signal("navDown")



func _on_up_pushButton():
	emit_signal("navUp")


func _on_left_pushButton():
	emit_signal("navLeft")


func _on_right_pushButton():
	emit_signal("navRight")
