extends CanvasLayer

#fade out, change the scene, fade in
#SceneTransition.changeScene("res://flat.tscn")
#a close-up keeps the flat in memory: SceneTransition.changeScene("res://zooms/...",0.0,true), the flat
#comes back as it was (no reload) when the close-up changes the scene to it

const FADE_DURATION=0.25
#dark purple of the cartoon palette, softer than black
const COLOR=Color(0.16,0.13,0.26)

var curtain=null
var busy=false
#scene out of the tree during a close-up, not freed
var keptScene=null

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
#keepCurrent_: the current scene is kept in memory, to come back to it without reloading it
func changeScene(path_,delay_=0.0,keepCurrent_=false):
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
	swapScene(path_,keepCurrent_)
	#the new scene draws its first frame under the curtain
	await get_tree().process_frame

	tween=create_tween()
	tween.tween_property(curtain,"modulate:a",0.0,FADE_DURATION).set_trans(Tween.TRANS_SINE)
	await tween.finished
	curtain.visible=false
	busy=false

func swapScene(path_,keepCurrent_):
	var tree=get_tree()
	var current=tree.current_scene

	var restored=keptScene!=null and keptScene.scene_file_path==path_
	var next=null
	if restored:
		next=keptScene
		keptScene=null
	else:
		#another scene (main menu, end screen): the kept one is not needed anymore
		clearKeptScene()
		next=load(path_).instantiate()

	if current:
		tree.root.remove_child(current)
		if keepCurrent_:
			keptScene=current
		else:
			current.queue_free()

	tree.root.add_child(next)
	tree.current_scene=next
	if restored and next.has_method("onRestored"):
		next.onRestored()
	tree.scene_changed.emit()

#new game, main menu: the flat is loaded again
func clearKeptScene():
	if keptScene:
		keptScene.queue_free()
		keptScene=null
