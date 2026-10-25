extends Node3D

@export var time: float=0.9

#minimum display time so the text can be read on a PC screen
const MIN_TIME=2.5

var tween=null

func setText(text_):
	$CanvasLayer/Panel/VBox/Label.text=text_
	#questions wait for the player to confirm with ui_accept
	$CanvasLayer/Panel/VBox/Hint.visible=text_.strip_edges().ends_with("?")

func showInfo(text_):
	#info disabled by its parent (ex: zoom scenes)
	if !is_visible_in_tree():
		return

	setText(text_)

	var panel=$CanvasLayer/Panel
	if !$CanvasLayer.visible:
		panel.modulate.a=0.0
		$CanvasLayer.visible=true
		if tween:
			tween.kill()
		tween=create_tween()
		tween.tween_property(panel,"modulate:a",1.0,0.15)

	$Timer.wait_time=max(time,MIN_TIME)
	$Timer.start()


func hideInfo():
	if tween:
		tween.kill()
	$Timer.stop()
	$CanvasLayer.visible=false



func _on_Timer_timeout():
	hideInfo()
