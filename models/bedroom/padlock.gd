extends Node3D

var minLine=1
var currentLine=1
var maxLine=4

var minNumber=0
var maxNumber=9

var codeList=[0,0,0,0]

@export var rightCode=[0,0,0,0] # (Array,int)

signal correctCode

const OPEN_DURATION=0.4

func open(animated_=true):
	var bloc=$bloc
	var target=bloc.position+bloc.basis*Vector3(0,1,0)
	if !animated_:
		bloc.position=target
		return
	var tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(bloc,"position",target,OPEN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func goDown():
	currentLine+=1
	if currentLine > maxLine:
		currentLine=minLine
	
	GlobalAudio.play("tick")
	resetThenSelectLine(currentLine)

func goUp():
	currentLine-=1
	if currentLine < minLine:
		currentLine=maxLine
	
	GlobalAudio.play("tick")
	resetThenSelectLine(currentLine)

func goLeft():
	var code=getCurrentCode()
	code-=1
	if code < minNumber:
		code=maxNumber
	GlobalAudio.play("tick")
	updateCurrentCode(code)

func goRight():
	var code=getCurrentCode()
	code+=1
	if code > maxNumber:
		code=minNumber
	GlobalAudio.play("tick")
	updateCurrentCode(code)

func getCurrentCode():
	return codeList[ (currentLine-1) ]
	
func isCodeCorrect():
	for i in range(0,4):
		if codeList[i]!=rightCode[i]:
			return false
	return true

func updateCurrentCode(code):
	codeList[ (currentLine-1) ]=code
	setLine(currentLine,str(code))
	
func resetThenSelectLine(number_):
	for i in range(1,5):
		unselectLine(i)
	selectLine(number_)

# Called when the node enters the scene tree for the first time.
func _ready():
	
	for i in range(1,5):
		setLine(i,str(0))
		unselectLine(i)
		print(str(i))

func unselectLine(number_):
	var node = get_node("bloc/line"+str(number_))
	var material = node.get_surface_override_material(0)
	material.albedo_color = Color(1, 1,1.25)
	node.set_surface_override_material(0, material)

	
func selectLine(number_):
	var node = get_node("bloc/line"+str(number_))
	var material = node.get_surface_override_material(0)
	material.albedo_color = Color(1, 0, 0,0.5)
	node.set_surface_override_material(0, material)

func setLine(number_,text_):
	get_node("bloc/line"+str(number_)+"/viewport/Label").text=text_
	get_node("bloc/line"+str(number_)+"/viewport").render_target_update_mode=SubViewport.UPDATE_ONCE
