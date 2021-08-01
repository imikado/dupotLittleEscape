extends CanvasLayer

signal movePlayer(joystickVector_)
signal moveHead(joystickVector_)

signal pushButtonA
signal pushButtonB

signal navLeft
signal navRight
signal navUp
signal navDown
 
var joystick_speed = 0;
var joystick_angle = 0;
var joystick_vector = Vector2();

var equipment=null

var _isEnable=true

export(bool) var displayLeftNav=false
export(bool) var displayLeftJoystick=false
export(bool) var displayRightJoystick=false

export(bool) var displayButtonA=false
export(bool) var displayButtonB=false

func _ready():
	if GlobalGame.isGamepadEnabled():
		enable()
	else:
		disable()

func disableHead():
	$"joystick-big2".visible=false

func enable():
	_isEnable=true
	$buttonA.visible=displayButtonA
	$buttonB.visible=displayButtonB
	$"joystick-big".visible=displayLeftJoystick
	$"joystick-big2".visible=displayRightJoystick
	$nav.visible=displayLeftNav

func disable():
	_isEnable=false
	$buttonA.visible=false
	$buttonB.visible=false
	$"joystick-big".visible=false
	$"joystick-big2".visible=false
	$nav.visible=false

func _on_button_pushButton():
	if _isEnable:
		emit_signal("pushButton")

func _on_button_releaseButton():
	if _isEnable:
		emit_signal("releaseButton")

func _on_joystickbig_moveJoystick(joystickVector_):
	if _isEnable:
		emit_signal("movePlayer",joystickVector_)

func enableButton():
	$button.visible=true

func setEquipment(item_):
	var realItem=GlobalItems.getItem(item_)
	$button/Sprite.texture=realItem.getTexture()
	enableButton()
	

func _on_HUD_equipItem(item_):
	setEquipment(item_)


func _on_buttonB_pushButton():
	emit_signal("pushButtonB")
	pass # Replace with function body.


func _on_buttonB_releaseButton():
	pass # Replace with function body.


func _on_buttonA_pushButton():
	emit_signal("pushButtonA")
	pass # Replace with function body.


func _on_buttonA_releaseButton():
	pass # Replace with function body.


func _on_joystickbig2_moveJoystick(joystickVector_):
	if _isEnable:
		emit_signal("moveHead",joystickVector_)
	pass # Replace with function body.


func _on_down_pushButton():
	emit_signal("navDown")



func _on_up_pushButton():
	emit_signal("navUp")


func _on_left_pushButton():
	emit_signal("navLeft")


func _on_right_pushButton():
	emit_signal("navRight")
