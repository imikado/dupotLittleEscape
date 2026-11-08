extends Node3D

#common input of the close-ups: arrows (keyboard, gamepad), touch nav buttons, touch joystick,
#accept (button A) and cancel (button B, back to the flat)
#the close-ups extend this script and override onDirection() and pushButtonA()

#false: one step per press of an arrow key, true: the arrow keys act every frame while held
var holdKeys=false

var left=false
var right=false
var up=false
var down=false
#the touch joystick keeps its direction until it moves again (held), the keys are read each frame
var useTouch=false


func _physics_process(delta_):
	processInput()

	var direction=Vector2i()
	if up:
		direction.y=-1
	if down:
		direction.y=1
	if left:
		direction.x=-1
	if right:
		direction.x=1

	resetKeys()

	if direction!=Vector2i():
		onDirection(direction,delta_)

	if Input.is_action_just_pressed("ui_accept"):
		pushButtonA()

	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()

#hook: direction_ of this frame, x: -1 left / 1 right, y: -1 up / 1 down
func onDirection(direction_,delta_):
	pass

#hook: accept (Enter, button A)
func pushButtonA():
	pass

#cancel (Backspace, button B), also called by the HUD "back" button of the pause menu
func pushButtonB():
	SceneTransition.changeScene("res://flat.tscn")

func isKeyActive(action_):
	if holdKeys:
		return Input.is_action_pressed(action_)
	return Input.is_action_just_pressed(action_)

func processInput():
	if isKeyActive("ui_right"):
		right=true
		useTouch=false
	if isKeyActive("ui_left"):
		left=true
		useTouch=false
	if isKeyActive("ui_down"):
		down=true
		useTouch=false
	if isKeyActive("ui_up"):
		up=true
		useTouch=false

func resetKeys():
	if useTouch:
		return

	resetNav()

func resetNav():
	right=false
	left=false
	down=false
	up=false


func _on_navigation_movePlayer(joystickVector_):
	useTouch=true

	resetNav()

	if abs(joystickVector_.x)>abs(joystickVector_.y):
		if joystickVector_.x>10:
			right=true
		elif joystickVector_.x<-10:
			left=true
	else:
		if joystickVector_.y>10:
			down=true
		elif joystickVector_.y<-10:
			up=true

func _on_navigation_pushButtonA():
	pushButtonA()

func _on_navigation_pushButtonB():
	pushButtonB()

#touch nav buttons: one step (read by the next physics frame)
func _on_navigation_navDown():
	resetNav()
	down=true

func _on_navigation_navLeft():
	resetNav()
	left=true

func _on_navigation_navRight():
	resetNav()
	right=true

func _on_navigation_navUp():
	resetNav()
	up=true
