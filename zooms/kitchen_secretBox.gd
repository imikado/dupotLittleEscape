extends Spatial

var room='kitchen'

var secretBox

var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false

func _ready():
	GlobalGame.initCamera($ARVROrigin,Vector3(0,0.3,-0.2))
		
	$secretBoxWithCode.init(room,"secretBox",GlobalItems.ID.EXIT_KEY)

	secretBox=$secretBoxWithCode
	




func _physics_process(delta):
	
	pocessInput()
	
	if up:
		secretBox.goLeft()
	if down:
		secretBox.goRight()
	if left:
		secretBox.goUp()
	if right:
		secretBox.goDown()
		
	resetKeys()
	
	if Input.is_action_just_pressed("ui_accept"):
		pushButtonA()
		
	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()

func pushButtonA():
	if !secretBox.isLocked():
		get_tree().change_scene("res://flat.tscn")
		return
	
	if secretBox.isCodeCorrect():
		showInfo("Code ok")
		secretBox.unlock()

	else:
		showInfo("Code incorrect")

func pushButtonB():
	get_tree().change_scene("res://flat.tscn")

func showInfo(text_):
	secretBox.showInfo(text_)

func resetKeys():
	if useTouch:
		return
		
	resetNav()
	
func resetNav():
	right=false
	left=false
	down=false
	up=false	
	
func pocessInput():
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
