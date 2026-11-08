extends "res://zooms/zoom.gd"


var room='bathroom'


func _ready():
	$toilet/secretBoxWithCode.init(room,"secretBoxWithCode",GlobalItems.ID.KITCHEN_KEY)
	if $toilet/secretBoxWithCode.isLocked():
		$toilet/secretBoxWithCode.startEditing()


func onDirection(direction_,delta_):
	#opened: the wheels do not turn anymore
	if !$toilet/secretBoxWithCode.isLocked():
		return
	
	#the wheels are side by side: left / right select a wheel, up / down change the digit
	if direction_.y<0:
		$toilet/secretBoxWithCode.goRight()
	if direction_.y>0:
		$toilet/secretBoxWithCode.goLeft()
	if direction_.x<0:
		$toilet/secretBoxWithCode.goUp()
	if direction_.x>0:
		$toilet/secretBoxWithCode.goDown()
		
		
func showInfo(text_):
	$toilet/secretBoxWithCode.showInfo(text_)
	
func pushButtonA():
	if !$toilet/secretBoxWithCode.isLocked():
		SceneTransition.changeScene("res://flat.tscn")
		return
		
	if $toilet/secretBoxWithCode.isCodeCorrect():
		GlobalAudio.play("code_ok",false)
		showInfo("INFO_CODE_OK")
		$toilet/secretBoxWithCode.unlock()

	else:
		GlobalAudio.play("code_wrong",false)
		showInfo("INFO_CODE_WRONG")
