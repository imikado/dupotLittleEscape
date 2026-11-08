extends Node3D

const CodeWheels=preload("res://common/abstracts/codeWheels.gd")

@export var rightCode=[0,0,0,0] # (Array,int)

var wheels=CodeWheels.new(self,"bloc","viewport")

const OPEN_DURATION=0.4

var opened=false

#called again when the room comes back from a close-up: opens only once
func open(animated_=true):
	if opened:
		return
	opened=true
	wheels.unselectAll()
	var bloc=$bloc
	var target=bloc.position+bloc.basis*Vector3(0,1,0)
	if !animated_:
		bloc.position=target
		return
	var tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(bloc,"position",target,OPEN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _ready():
	wheels.reset()

func goDown():
	wheels.goDown()

func goUp():
	wheels.goUp()

func goLeft():
	wheels.goLeft()

func goRight():
	wheels.goRight()

func isCodeCorrect():
	return wheels.isCodeCorrect(rightCode)

#close-up: the selected wheel is highlighted (not in the room)
func startEditing():
	wheels.startEditing()
