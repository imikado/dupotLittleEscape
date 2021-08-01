extends KinematicBody

signal gotoInventory

const SPEED= 160
const ROTATE_SPEED=80
const GRAVITY=10

var vel = Vector3()

var nearObject = null

#keys
var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false

func _ready():
	GlobalGame.initCamera($ARVROrigin,Vector3())

func getCameraPosition():
	return global_transform.basis

func loadCameraPosition(position_):
	global_transform.basis=position_

func _physics_process(delta):
	var dir = Vector3()
	dir.y-=GRAVITY
	
	var rotateY=0
	var rotateX=0
	var moving=0
	
	pocessInput()

	if up:
		moving=1
	if down:
		moving=-1
		
	if left:
		rotateX=1
	if right:
		rotateX=-1
		
	if pageUp:
		rotateY=1
	if pageDown:
		rotateY=-1
		

	dir += -global_transform.basis.z * moving * SPEED * delta
	
	if rotateX!=0:
		
		global_transform.basis=global_transform.basis.rotated(Vector3(0,1,0),deg2rad( rotateX * ROTATE_SPEED) * delta)
	
		
	
	if rotateY!=0:
		
		$ARVROrigin.rotate_object_local(Vector3(1,0,0),deg2rad( rotateY * ROTATE_SPEED) * delta)
	

	vel = move_and_slide(dir)

	if Input.is_action_just_pressed("ui_accept"):
		pushButtonA()
	
	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()
		
	resetKeys()

func pushButtonA():
	if nearObject && nearObject.has_method("action"):
			if nearObject.has_method("canRetrieveItem") && nearObject.canRetrieveItem():
				var item=nearObject.getItem()
				GlobalPlayer.addItem(item)
				return

			nearObject.action()
			
func pushButtonB():
	emit_signal("gotoInventory")

func _on_contact_body_entered(body):
	if body.has_method('displayInfo'):
		body.displayInfo()
		
		nearObject=body


func _on_contact_body_exited(body):
	if body.has_method('hideInfo'):
		body.hideInfo()
		
		nearObject=null


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
	pageUp=false
	pageDown=false

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
		


func _on_navigation_pushButtonA():
	pushButtonA()
	pass # Replace with function body.


func _on_navigation_pushButtonB():
	pushButtonB()
	pass # Replace with function body.


func _on_navigation_moveHead(joystickVector_):
	useTouch=true
	
	pageUp=false
	pageDown=false
	
	if abs(joystickVector_.x) <= abs(joystickVector_.y) :
	
	 
		if(joystickVector_.y > 10):
			pageDown=true
		elif(joystickVector_.y < -10):
			pageUp=true
	pass # Replace with function body.
