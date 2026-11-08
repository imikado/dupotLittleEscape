extends "res://zooms/zoom.gd"

var room="livingRoom"

var selectedX=0
var selectedY=0

var screen=""

var numberList=[
	[1,2,3],
	[4,5,6],
	[7,8,9],
	["E",0,"A"]
]

#center of the key "1" and distance between two keys
const KEY_ORIGIN=Vector3(-0.724,0.62,-1.262)
const KEY_STEP=0.7
#the selection frame floats up and down a little
const SELECTED_BOB=0.025
const SELECTED_BOB_SPEED=5.0
#more digits do not fit on the display
const MAX_DIGITS=6

var time=0.0

#Tour bleu   2
#Roi rouge    1
#Fou Bleu    5
#Tour rouge  3

func _ready():
	refreshScreen()

func _process(delta):
	time+=delta
	$selected.position=KEY_ORIGIN+Vector3(selectedX*KEY_STEP,sin(time*SELECTED_BOB_SPEED)*SELECTED_BOB,selectedY*KEY_STEP)

func onDirection(direction_,delta_):
	#the selection stays on the keypad
	if 2 < selectedX+direction_.x or selectedX+direction_.x < 0:
		return
		
	if 3 < selectedY+direction_.y or selectedY+direction_.y < 0:
		return
	
	GlobalAudio.play("tick")

	selectedX+=direction_.x
	selectedY+=direction_.y


func pushButtonA():
	GlobalAudio.play("beep")
	var touchPressed = str(numberList[selectedY][selectedX])
	if touchPressed=="E":
		screen=screen.substr(0, screen.length()-1  )	
	elif touchPressed=="A":
		#nothing typed: the TV keeps its channel
		if screen!="":
			GlobalRoom.saveStateForObject(room,"tv",{"channel":screen})
		SceneTransition.changeScene("res://flat.tscn")
		return
	elif screen.length()<MAX_DIGITS:
		screen+=""+ touchPressed
	
	refreshScreen()

func refreshScreen():
	$SubViewport/Label.text="CH "+(screen if screen!="" else "----")
