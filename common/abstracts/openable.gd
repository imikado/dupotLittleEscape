extends Node3D

#moving part of a furniture (door, drawer, cover...): open() and close() animate it with a cartoon
#overshoot and play its sound, open(false) moves it at once (state restored when a scene is loaded)

const OPEN_DURATION=0.55
const CLOSE_DURATION=0.45

#from closed to opened, set by the child scripts in _init:
#rotation in degrees around an axis of the parent space (like rotate()), translation in global space
#(like global_translate())
var openAxis=Vector3.UP
var openAngle=0.0
var openOffset=Vector3.ZERO
var openSound=""
var closeSound=""
#swing side (1 or -1), e.g. a door opens away from the player
var openDirection=1.0
#false: the collision shapes of the part only collide when it is closed (a door swinging open
#would push the player and get them stuck against it)
var solidWhenOpened=true

var closedTransform=null
var progress=0.0
var tween=null

func open(animated_=true):
	moveTo(1.0,OPEN_DURATION,openSound,animated_)

func close(animated_=true):
	moveTo(0.0,CLOSE_DURATION,closeSound,animated_)

func moveTo(target_,duration_,sound_,animated_):
	if closedTransform==null:
		closedTransform=transform
	if tween:
		tween.kill()
	if !animated_:
		setProgress(target_)
		return

	if sound_!="":
		GlobalAudio.play(sound_)
	#physics process: the transform is interpolated between physics ticks
	tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if target_>progress:
		#swings a bit too far, then comes back
		tween.tween_method(setProgress,progress,target_,duration_).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		#bounces against the frame
		tween.tween_method(setProgress,progress,target_,duration_).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func setProgress(progress_):
	progress=progress_
	var basis=closedTransform.basis.rotated(openAxis.normalized(),deg_to_rad(openAngle*openDirection*progress))
	var origin=closedTransform.origin
	if openOffset!=Vector3.ZERO:
		var parent=get_parent()
		var parentBasis=parent.global_transform.basis if parent is Node3D else Basis()
		origin+=parentBasis.inverse()*openOffset*progress
	transform=Transform3D(basis,origin)

	if !solidWhenOpened:
		for shape in find_children("*","CollisionShape3D",true,false):
			#deferred: may be called during a physics step
			shape.set_deferred("disabled",progress>0.001)

#swing side that moves the part away from a position (the player), on the ground
func getAwayDirection(from_):
	if closedTransform==null:
		closedTransform=transform
	var center=call("get_aabb").get_center() if has_method("get_aabb") else Vector3.ZERO
	var parentTransform=get_parent().global_transform
	var from=Vector2(from_.x,from_.z)
	var best=1.0
	var bestDistance=-1.0
	for direction in [1.0,-1.0]:
		var basis=closedTransform.basis.rotated(openAxis.normalized(),deg_to_rad(openAngle*direction))
		var position=parentTransform*Transform3D(basis,closedTransform.origin)*center
		var distance=Vector2(position.x,position.z).distance_to(from)
		if distance>bestDistance:
			best=direction
			bestDistance=distance
	return best
