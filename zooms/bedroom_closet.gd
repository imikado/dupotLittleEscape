extends "res://zooms/zoom.gd"

var room="bedroom"

func _ready():

	$closet.init(room,"closet",GlobalItems.ID.BEDROOM_KEY)

	$closet.zoom()
	
	$info.hideInfo()

func onDirection(direction_,delta_):
	#opened: the wheels do not turn anymore
	if !$closet.isLocked():
		return
	
	if direction_.y<0:
		$closet.goUp()
	if direction_.y>0:
		$closet.goDown()
	if direction_.x<0:
		$closet.goLeft()
	if direction_.x>0:
		$closet.goRight()
		
func pushButtonA():
	if !$closet.isLocked():
		SceneTransition.changeScene("res://flat.tscn")
		return
	
	if $closet.isSecretCode():
		GlobalAudio.play("code_ok",false)
		showInfo("INFO_CODE_OK")
		$closet.unlock()
	else:
		GlobalAudio.play("code_wrong",false)
		showInfo("INFO_CODE_WRONG")

func showInfo(text_):
	$info.showInfo(text_)
