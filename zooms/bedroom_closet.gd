extends Spatial

var room="bedroom"

#keys
var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false

func _ready():
	GlobalGame.initCamera($ARVROrigin,Vector3(0,0,-0.1))

	$closet.init(room,"closet",GlobalItems.ID.BEDROOM_KEY)

	$closet.zoom()
	
	$info.hideInfo()
	


func _physics_process(delta):
	
	pocessInput()
	
	if up:
		$closet.goUp()
	if down:
		$closet.goDown()
	if left:
		$closet.goLeft()
	if right:
		$closet.goRight()
		
	resetKeys()
	
	if Input.is_action_just_pressed("ui_accept"):
		pushButtonA()
		
	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()
		
func pushButtonA():
	if !$closet.isLocked():
		get_tree().change_scene("res://flat.tscn")
		return
	
	if $closet.isSecretCode():
		showInfo("Code ok")
		$closet.unlock()
	else:
		showInfo("Code incorrect")

func pushButtonB():
	get_tree().change_scene("res://flat.tscn")

func showInfo(text_):
	$info.showInfo(text_)
	#$Timer.start()
	
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

func _on_Timer_timeout():
	$info.hideInfo()


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
