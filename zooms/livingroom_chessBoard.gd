extends Spatial

var vel = Vector3()
const SPEED= 160
const ROTATE_SPEED=80

var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false


func _ready():
	GlobalGame.initCamera($ARVROrigin,Vector3(0,0,0.4))
		
	$chess_board.disableInfo()



func _physics_process(delta):
	var dir = Vector3()
	
	var rotate=0
	var moving=0
	
	pocessInput()

	if Input.is_action_pressed("ui_up"):
		#moving=1
		pass
	if Input.is_action_pressed("ui_down"):
		#moving=-1
		pass
		
	if left:
		rotate=1
	if right:
		rotate=-1

	resetKeys()

	dir += -global_transform.basis.z * moving * SPEED * delta
	
	if rotate!=0:
		$chess_board.rotate_y( deg2rad( rotate * ROTATE_SPEED) * delta )
	
	if moving!=0:
		$chess_board.translate(   Vector3(0,  (moving * ROTATE_SPEED) * delta ,0 ))
		
	
	
	#vel = move_and_slide(dir)
	
	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()
		
func pocessInput():
	if Input.is_action_pressed("ui_right"):
		right=true
		useTouch=false
	if Input.is_action_pressed("ui_left"):
		left=true
		useTouch=false
	if Input.is_action_pressed("ui_down"):
		down=true
		useTouch=false
	if Input.is_action_pressed("ui_up"):
		up=true
		useTouch=false
	if Input.is_action_pressed("ui_page_up"):
		pageUp=true
		useTouch=false
	if Input.is_action_pressed("ui_page_down"):
		pageDown=true
		useTouch=false
		
func pushButtonB():
	get_tree().change_scene("res://flat.tscn")
	



func _on_navigation_movePlayer(joystickVector_):
	useTouch=true
	
	right=false
	left=false
	down=false
	up=false	
	
	if abs(joystickVector_.x)>abs(joystickVector_.y) :
	
		if(joystickVector_.x > 10):
			right=true
		elif(joystickVector_.x < -10):
			left=true
	 
	else:
				
		if(joystickVector_.y > 10):
			down=true
		elif(joystickVector_.y < -10):
			up=true
	pass # Replace with function body.

func resetKeys():
	if useTouch:
		return
		
	left=false
	right=false
	up=false
	down=false


func _on_navigation_pushButtonB():
	pushButtonB()
	pass # Replace with function body.
