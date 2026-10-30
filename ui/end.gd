extends Control

#pop-in of the window, then the title floats gently
const POP_DURATION=0.45
const FLOAT_HEIGHT=6.0
const FLOAT_DURATION=1.2

@onready var window=$center/window
@onready var title=$center/window/content/title

func _ready():
	var vr_interface=XRServer.find_interface("Native mobile")
	if vr_interface and vr_interface.initialize():
			get_viewport().use_xr=false

	#keyboard / gamepad: Enter validates directly
	$center/window/content/goBackToMenu.grab_focus.call_deferred()
	popIn.call_deferred()
	GlobalAudio.play("win",false)

#deferred: the containers have computed the sizes
func popIn():
	window.pivot_offset=window.size/2
	window.scale=Vector2(0.6,0.6)
	window.modulate.a=0.0
	var tween=create_tween().set_parallel()
	tween.tween_property(window,"scale",Vector2.ONE,POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(window,"modulate:a",1.0,POP_DURATION*0.5)
	tween.chain().tween_callback(floatTitle)

func floatTitle():
	var start=title.position.y
	var tween=create_tween().set_loops()
	tween.tween_property(title,"position:y",start-FLOAT_HEIGHT,FLOAT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title,"position:y",start,FLOAT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_Button_pressed():
	SceneTransition.changeScene("res://ui/Menu.tscn")
