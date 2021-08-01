extends Spatial


var room='bathroom'

#keys
var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false


func _ready():
	GlobalGame.initCamera($ARVROrigin,Vector3(0,0,0.4))
	
	$toilet/secretBoxWithCode.init(room,"secretBoxWithCode",GlobalItems.ID.KITCHEN_KEY)
	#$toilet/secretBoxWithCode.disableInfo()
	
	#$toilet/secretBoxWithCode.openCover()


func _physics_process(delta):
	
	pocessInput()
	
	if up:
		$toilet/secretBoxWithCode.goLeft()
	if down:
		$toilet/secretBoxWithCode.goRight()
	if left:
		$toilet/secretBoxWithCode.goUp()
	if right:
		$toilet/secretBoxWithCode.goDown()
	
	resetKeys()
	
	if Input.is_action_just_pressed("ui_accept"):
		pushButtonA()
		
	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()
		
		
func showInfo(text_):
	$toilet/secretBoxWithCode.showInfo(text_)
	
func pushButtonB():
	get_tree().change_scene("res://flat.tscn")
	
func pushButtonA():
	if !$toilet/secretBoxWithCode.isLocked():
		get_tree().change_scene("res://flat.tscn")
		return
		
	if $toilet/secretBoxWithCode.isCodeCorrect():
		showInfo("Code ok")
		$toilet/secretBoxWithCode.unlock()

	else:
		showInfo("Code incorrect")


func _on_navigation_movePlayer(joystickVector_):
	useTouch=true
	
	right=false
	left=false
	down=false
	up=false	
	
	if abs(joystickVector_.x)>abs(joystickVector_.y) :
	
		if(joystickVector_.x > 10):
			right=true
		elif(joystickVector_.x < -10):
			left=true
	 
	else:
				
		if(joystickVector_.y > 10):
			down=true
		elif(joystickVector_.y < -10):
			up=true
	pass # Replace with function body.

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
