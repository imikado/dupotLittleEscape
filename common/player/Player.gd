extends CharacterBody3D

signal gotoInventory

#full speed: meters per second, degrees per second
const SPEED=2.67
const ROTATE_SPEED=80.0
const GRAVITY=10
#time to reach the full speed and to stop: smooth start and stop
const ACCELERATION_TIME=0.15
const DECELERATION_TIME=0.12

#touch joystick: knob offset at full tilt, smaller values are ignored (dead zone)
const JOYSTICK_MAX=16.0
const JOYSTICK_DEADZONE=0.25

var nearObject = null

#tilt the camera down to see low furniture (bedside table, coffee table...)
const LOW_OBJECT_MARGIN=0.5
const MAX_TILT=-60.0
const TILT_SPEED=5.0
var tiltObject=null
var tiltAabb=null

#current speeds (-1 to 1), they follow the inputs smoothly
var moving=0.0
var turning=0.0
#touch joystick (-1 to 1)
var touchMoving=0.0
var touchTurning=0.0

func getCameraPosition():
	return global_transform.basis

func loadCameraPosition(position_):
	global_transform.basis=position_

func _physics_process(delta):
	updateNearObject()
	updateTilt(delta)

	#keyboard, gamepad stick (analog) and touch joystick
	var targetMoving=clamp(Input.get_axis("ui_down","ui_up")+touchMoving,-1.0,1.0)
	var targetTurning=clamp(Input.get_axis("ui_right","ui_left")+touchTurning,-1.0,1.0)
	moving=smooth(moving,targetMoving,delta)
	turning=smooth(turning,targetTurning,delta)

	if turning!=0.0:
		global_transform.basis=global_transform.basis.rotated(Vector3.UP,deg_to_rad(turning*ROTATE_SPEED)*delta)

	velocity=-global_transform.basis.z*moving*SPEED
	velocity.y=-GRAVITY
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		pushButtonA()

	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()

#speeds up to the target, slows down faster (also when going the other way)
func smooth(current_,target_,delta_):
	var accelerating=abs(target_)>abs(current_) and current_*target_>=0.0
	return move_toward(current_,target_,delta_/(ACCELERATION_TIME if accelerating else DECELERATION_TIME))

func pushButtonA():
	if nearObject && nearObject.has_method("action"):
			if nearObject.has_method("canRetrieveItem") && nearObject.canRetrieveItem():
				var item=nearObject.getItem()
				GlobalPlayer.addItem(item)
				GlobalAudio.play("pickup",false)
				return

			nearObject.action()

func pushButtonB():
	emit_signal("gotoInventory")

#several objects in reach (chessboard and remote control on the coffee table...): the one closest
#to the center of the contact zone, so the player can choose by moving or turning
func updateNearObject():
	var center=$XROrigin3D/contact/CollisionShape3D.global_position
	var nearest=null
	var nearestDistance=INF
	for body in $XROrigin3D/contact.get_overlapping_bodies():
		if !body.has_method('displayInfo'):
			continue
		var position=getObjectCenter(body)
		var distance=Vector2(position.x-center.x,position.z-center.z).length()
		if distance<nearestDistance:
			nearest=body
			nearestDistance=distance

	if nearest==nearObject:
		return
	if is_instance_valid(nearObject):
		if nearObject.has_method('hideInfo'):
			nearObject.hideInfo()
		#highlight of the targeted object
		if nearObject.has_method('setTargeted'):
			nearObject.setTargeted(false)
	nearObject=nearest
	if nearObject:
		nearObject.displayInfo()
		if nearObject.has_method('setTargeted'):
			nearObject.setTargeted(true)

func getObjectCenter(object_):
	var shape=object_.get_node_or_null("CollisionShape3D")
	return shape.global_position if shape else object_.global_position

func _on_contact_body_entered(body):
	if isLowObject(body):
		setTiltObject(body)


func _on_contact_body_exited(body):
	if body==tiltObject:
		setTiltObject(null)

	#fall back on another object still in reach
	for other in $XROrigin3D/contact.get_overlapping_bodies():
		if other==body:
			continue
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

#only the camera tilts: the contact zone stays level
func updateTilt(delta):
	var target=0.0
	if tiltObject and is_instance_valid(tiltObject):
		target=getTiltAngle()

	var camera=$XROrigin3D/Camera3D
	camera.rotation_degrees.x=lerp(camera.rotation_degrees.x,target,min(1.0,delta*TILT_SPEED))

#touch joystick: up/down moves, left/right turns, both at once (analog)
func _on_navigation_movePlayer(joystickVector_):
	var vector=joystickVector_/JOYSTICK_MAX
	touchMoving=-applyDeadzone(vector.y)
	touchTurning=-applyDeadzone(vector.x)

func applyDeadzone(value_):
	if abs(value_)<JOYSTICK_DEADZONE:
		return 0.0
	return sign(value_)*inverse_lerp(JOYSTICK_DEADZONE,1.0,min(abs(value_),1.0))

func _on_navigation_pushButtonA():
	pushButtonA()


func _on_navigation_pushButtonB():
	pushButtonB()
