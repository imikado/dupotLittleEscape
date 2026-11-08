extends RefCounted

#4-digit code wheels shared by the padlock and the secret box
#(composition: their base classes differ)
#each wheel is a mesh "<linesPath>/lineN" showing a Label inside "<viewportName>"

const SELECTED_COLOR=Color(1.0,0.78,0.2)
const UNSELECTED_COLOR=Color(1,1,1.25)

var minLine=1
var currentLine=1
var maxLine=4

var minNumber=0
var maxNumber=9

var codeList=[0,0,0,0]

var ownerNode=null
var linesPath=""
var viewportName=""

func _init(owner_,linesPath_,viewportName_):
	ownerNode=owner_
	linesPath=linesPath_
	viewportName=viewportName_

#all wheels at 0, none highlighted
func reset():
	for i in range(minLine,maxLine+1):
		setLine(i,str(0))
		unselectLine(i)

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

#rightCode stays an export of the owner (set in the .tscn files)
func isCodeCorrect(rightCode_):
	for i in range(0,4):
		if codeList[i]!=rightCode_[i]:
			return false
	return true

func updateCurrentCode(code_):
	codeList[ (currentLine-1) ]=code_
	setLine(currentLine,str(code_))

#close-up: the selected wheel is highlighted (not in the room)
func startEditing():
	resetThenSelectLine(currentLine)

func resetThenSelectLine(number_):
	unselectAll()
	selectLine(number_)

func unselectAll():
	for i in range(minLine,maxLine+1):
		unselectLine(i)

func unselectLine(number_):
	setLineColor(number_,UNSELECTED_COLOR)

func selectLine(number_):
	#warm yellow: the digit stays readable
	setLineColor(number_,SELECTED_COLOR)

func setLineColor(number_,color_):
	var node=getLine(number_)
	var material=node.get_surface_override_material(0)
	material.albedo_color=color_
	node.set_surface_override_material(0,material)

func setLine(number_,text_):
	var viewport=getLine(number_).get_node(viewportName)
	viewport.get_node("Label").text=text_
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func getLine(number_):
	return ownerNode.get_node(linesPath+"/line"+str(number_))
