extends Sprite2D

signal pushButton
signal releaseButton

#radius of the circle drawn in the texture (pixels)
const RADIUS=16
#a bit bigger than the drawn circle: easier to hit with a finger
const TOUCH_MARGIN=1.3

#finger pressing the button (several fingers on the screen: joystick + buttons)
var touchIndex=-1

func _input(event):
	if !is_visible_in_tree() or !(event is InputEventScreenTouch):
		return
	if event.is_pressed():
		if touchIndex==-1 and global_position.distance_to(event.position) < RADIUS*global_scale.x*TOUCH_MARGIN:
			touchIndex=event.index
			emit_signal("pushButton")
	elif event.index==touchIndex:
		touchIndex=-1
		emit_signal("releaseButton")
