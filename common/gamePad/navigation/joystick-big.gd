extends Sprite2D

signal moveJoystick(joystickVector)

#in the texture (pixels): the big circle and the knob circle
const RADIUS = 32
const SMALL_RADIUS = 16
#the finger can start a bit outside the drawn circle
const TOUCH_MARGIN = 1.3

#finger moving the joystick (several fingers on the screen: joystick + buttons)
var touchIndex=-1

#access
func getSmall():
	return $"joystick-small"

#screen distance -> texture distance (the sprite is scaled)
func getTouchRadius():
	return RADIUS*global_scale.x*TOUCH_MARGIN

func _input(event_):
	if !is_visible_in_tree():
		return
	if event_ is InputEventScreenTouch:
		if event_.is_pressed():
			if touchIndex==-1 and global_position.distance_to(event_.position) < getTouchRadius():
				touchIndex=event_.index
				moveKnob(event_.position)
		elif event_.index==touchIndex:
			touchIndex=-1
			getSmall().position=Vector2()
			emit_signal("moveJoystick",getSmall().position)

	elif event_ is InputEventScreenDrag and event_.index==touchIndex:
		moveKnob(event_.position)

#knob offset in the texture, at most RADIUS - SMALL_RADIUS (inside the big circle)
func moveKnob(position_):
	var offset=(position_-global_position)/global_scale.x
	getSmall().position=offset.limit_length(RADIUS-SMALL_RADIUS)
	emit_signal("moveJoystick",getSmall().position)
