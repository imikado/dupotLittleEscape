extends CharacterBody3D

signal gotoInventory

const SPEED= 160
const ROTATE_SPEED=80
const GRAVITY=10

var vel = Vector3()

var nearObject = null

#tilt the camera down to see low furniture (bedside table, coffee table...)
const LOW_OBJECT_MARGIN=0.5
const MAX_TILT=-60.0
const TILT_SPEED=5.0
var tiltObject=null
var tiltAabb=null

#keys
var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false

func _ready():
	GlobalGame.initCamera($XROrigin3D,Vector3())

func getCameraPosition():
	return global_transform.basis

func loadCameraPosition(position_):
	global_transform.basis=position_

func _physics_process(delta):
	updateTilt(delta)

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
		
		global_transform.basis=global_transform.basis.rotated(Vector3(0,1,0),deg_to_rad( rotateX * ROTATE_SPEED) * delta)
	
		
	
	if rotateY!=0:
		
		$XROrigin3D.rotate_object_local(Vector3(1,0,0),deg_to_rad( rotateY * ROTATE_SPEED) * delta)
	

	set_velocity(dir)
	move_and_slide()
	vel = velocity

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

	if isLowObject(body):
		setTiltObject(body)


func _on_contact_body_exited(body):
	if body.has_method('hideInfo'):
		body.hideInfo()

		if body==nearObject:
			nearObject=null

	if body==tiltObject:
		setTiltObject(null)

	#fall back on another object still in reach
	for other in $XROrigin3D/contact.get_overlapping_bodies():
		if other==body:
			continue
		if nearObject==null and other.has_method('displayInfo'):
			other.displayInfo()
			nearObject=other
		if tiltObject==null and isLowObject(other):
			setTiltObject(other)

func getObjectAabb(object_):
	var aabb=null
	for mesh in object_.find_children("*","MeshInstance3D",true,false):
		if !mesh.is_visible_in_tree():
			continue
		var meshAabb=mesh.global_transform * mesh.get_aabb()
		aabb=meshAabb if aabb==null else aabb.merge(meshAabb)
	return aabb

func isLowObject(object_):
	var aabb=getObjectAabb(object_)
	if aabb==null:
		return false
	return aabb.end.y < $XROrigin3D/Camera3D.global_position.y-LOW_OBJECT_MARGIN

#the furniture bounds are computed once, not every physics frame
func setTiltObject(object_):
	tiltObject=object_
	tiltAabb=getObjectAabb(object_) if object_ else null

func getTiltAngle():
	var aabb=tiltAabb
	if aabb==null:
		return 0.0

	var camera=$XROrigin3D/Camera3D
	var top=aabb.get_center()
	top.y=aabb.end.y

	var distance=Vector2(top.x-camera.global_position.x,top.z-camera.global_position.z).length()
	var angle=rad_to_deg(atan2(top.y-camera.global_position.y,distance))
	return max(angle,MAX_TILT)

func updateTilt(delta):
	var target=0.0
	if tiltObject and is_instance_valid(tiltObject):
		target=getTiltAngle()

	var camera=$XROrigin3D/Camera3D
	camera.rotation_degrees.x=lerp(camera.rotation_degrees.x,target,min(1.0,delta*TILT_SPEED))


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
