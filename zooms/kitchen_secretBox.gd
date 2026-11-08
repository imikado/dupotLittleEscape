extends "res://zooms/zoom.gd"

var room='kitchen'

var secretBox

func _ready():
	$secretBoxWithCode.init(room,"secretBox",GlobalItems.ID.EXIT_KEY)

	secretBox=$secretBoxWithCode
	if secretBox.isLocked():
		secretBox.startEditing()

func onDirection(direction_,delta_):
	#opened: the wheels do not turn anymore
	if !secretBox.isLocked():
		return
	
	#the wheels are side by side: left / right select a wheel, up / down change the digit
	if direction_.y<0:
		secretBox.goRight()
	if direction_.y>0:
		secretBox.goLeft()
	if direction_.x<0:
		secretBox.goUp()
	if direction_.x>0:
		secretBox.goDown()

func pushButtonA():
	if !secretBox.isLocked():
		SceneTransition.changeScene("res://flat.tscn")
		return
	
	if secretBox.isCodeCorrect():
		GlobalAudio.play("code_ok",false)
		showInfo("INFO_CODE_OK")
		secretBox.unlock()

	else:
		GlobalAudio.play("code_wrong",false)
		showInfo("INFO_CODE_WRONG")

func showInfo(text_):
	secretBox.showInfo(text_)
