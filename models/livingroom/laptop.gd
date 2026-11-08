extends "res://common/abstracts/furniture.gd"

#the screen fades in from black when switched on, and back to black when switched off
const SWITCH_ON_DURATION=0.5
const SWITCH_OFF_DURATION=0.3

var tween=null

func _ready():
	defaultProps={
		"state":CLOSED
	}
	
func refreshState():
	if props.state==OPENED:
		switchOnScreen(false)
			
func resetScreens():
	$screenOff.visible=false
	$screenOn.visible=false

#albedo of the screen picture: black (off) to white (on)
func setBrightness(brightness_):
	$screenOn.get_active_material(0).albedo_color=Color(brightness_,brightness_,brightness_)

func switchOnScreen(animated_=true):
	if tween:
		tween.kill()
	resetScreens()
	$screenOn.visible=true
	if !animated_:
		setBrightness(1.0)
		return
	setBrightness(0.0)
	tween=create_tween()
	tween.tween_method(setBrightness,0.0,1.0,SWITCH_ON_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
func switchOffScreen():
	if tween:
		tween.kill()
	tween=create_tween()
	tween.tween_method(setBrightness,1.0,0.0,SWITCH_OFF_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		resetScreens()
		$screenOff.visible=true
	)
	
func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_LAPTOP_ON")
	else:
		showInfo("INFO_LAPTOP_OFF")


func action():
	GlobalAudio.play("switch")
	if props.state==CLOSED:
		switchOnScreen()
		
		props.state=OPENED
	else:
		switchOffScreen()
		
		props.state=CLOSED
	
	saveProps()
		
	displayInfo()
