extends CanvasLayer

#fade out, change the scene, fade in
#SceneTransition.changeScene("res://flat.tscn")

const FADE_DURATION=0.25
#dark purple of the cartoon palette, softer than black
const COLOR=Color(0.16,0.13,0.26)

var curtain=null
var busy=false

func _ready():
	#above the HUD, the info panels and the pause menu
	layer=100
	process_mode=Node.PROCESS_MODE_ALWAYS

	curtain=ColorRect.new()
	curtain.color=COLOR
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	#no click on the scene below during the fade
	curtain.mouse_filter=Control.MOUSE_FILTER_STOP
	curtain.modulate.a=0.0
	curtain.visible=false
	add_child(curtain)

func isBusy():
	return busy

#delay_: time to see the last animation (the exit door opening...) before the fade
func changeScene(path_,delay_=0.0):
	#a second request during the fade (Backspace pressed twice...) is ignored
	if busy:
		return
	busy=true

	if delay_>0.0:
		await get_tree().create_timer(delay_).timeout

	curtain.visible=true
	var tween=create_tween()
	tween.tween_property(curtain,"modulate:a",1.0,FADE_DURATION).set_trans(Tween.TRANS_SINE)
	await tween.finished

	get_tree().paused=false
	get_tree().change_scene_to_file(path_)
	await get_tree().scene_changed

	tween=create_tween()
	tween.tween_property(curtain,"modulate:a",0.0,FADE_DURATION).set_trans(Tween.TRANS_SINE)
	await tween.finished
	curtain.visible=false
	busy=false
