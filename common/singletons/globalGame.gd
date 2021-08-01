extends Node

var vrEnabled=true
var gamepadEnabled=false

func setVrEnabled(bool_):
	vrEnabled=bool_
	
func isVRenabled():
	return vrEnabled

func setGamepadEnabled(bool_):
	gamepadEnabled=bool_

func isGamepadEnabled():
	return gamepadEnabled




func _ready():
	pass # Replace with function body.

func initCamera(arvrOrigin_,vectorNonVr_):
	return
	var vr_interface=ARVRServer.find_interface("Native mobile")
	if vr_interface and vr_interface.initialize():
			get_viewport().arvr=isVRenabled()
			get_viewport().hdr=false

	if !isVRenabled():
		pass
		arvrOrigin_.global_translate(vectorNonVr_)
