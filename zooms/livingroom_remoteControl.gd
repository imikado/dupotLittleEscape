extends Spatial

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

var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false

#Tour bleu   2
#Roi rouge    1
#Fou Bleu    5
#Tour rouge  3

func _ready():
	GlobalGame.initCamera($ARVROrigin,Vector3(0,0.8,-0.7))

func _physics_process(delta):
	var dir = Vector3()
	
	var movingCase=2.3
	
	var movingX=0
	var movingY=0
	
	processInput()
	
	if up:
		movingY=-1		
	if down:
		movingY=1
	if left:
		movingX=-1
	if right:
		movingX=1
	
	resetKeys()
	
	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()
	
	if Input.is_action_just_pressed("ui_accept"):
		pushButtonA()
		

	if 2 < selectedX+movingX or selectedX+movingX < 0:
		return
		
	if 3 < selectedY+movingY or selectedY+movingY < 0:
		return
	
	if movingX!=0:
		selectedX+=movingX
		
	if movingY!=0:
		selectedY+=movingY
	
	if movingX!=0 or movingY!=0:
		$selected.translate(   Vector3(movingX*movingCase, 0 ,movingY*movingCase ))


func pushButtonA():
	var touchPressed = str(numberList[selectedY][selectedX])
	if touchPressed=="E":
		screen=screen.substr(0, screen.length()-1  )	
	elif touchPressed=="A":
		GlobalRoom.saveStateForObject(room,"tv",{"channel":screen})
		get_tree().change_scene("res://flat.tscn")
		return
	else:
		screen+=""+ touchPressed
	
	$Viewport/Label.text=screen
		
func pushButtonB():
	get_tree().change_scene("res://flat.tscn")
		
func resetKeys():
	if useTouch:
		return
		
	resetNav()
	
func resetNav():
	right=false
	left=false
	down=false
	up=false	
	
func processInput():
	if Input.is_action_just_pressed("ui_right"):
		right=true
		useTouch=false
	if Input.is_action_just_pressed("ui_left"):
		left=true
		useTouch=false
	if Input.is_action_just_pressed("ui_down"):
		down=true
		useTouch=false
	if Input.is_action_just_pressed("ui_up"):
		up=true
		useTouch=false
	if Input.is_action_just_pressed("ui_page_up"):
		pageUp=true
		useTouch=false
	if Input.is_action_just_pressed("ui_page_down"):
		pageDown=true
		useTouch=false
		
func _on_navigation_pushButtonA():
	pushButtonA()


func _on_navigation_pushButtonB():
	pushButtonB()


func _on_navigation_navDown():
	resetNav()
	down=true


func _on_navigation_navLeft():
	resetNav()
	left=true


func _on_navigation_navRight():
	resetNav()
	right=true


func _on_navigation_navUp():
	resetNav()
	up=true

