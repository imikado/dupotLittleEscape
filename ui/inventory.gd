extends Spatial


var speed=3

#keys
var left=false
var right=false
var up=false
var down=false
var pageUp=false
var pageDown=false
var useTouch=false


# Called when the node enters the scene tree for the first time.
func _ready():
	
	#GlobalPlayer.addItem(GlobalItems.ID.PAPER)
	#GlobalPlayer.addItem(GlobalItems.ID.POSTIT)
	GlobalGame.initCamera($ARVROrigin,Vector3(0,0,0.4))
		
	var itemList=GlobalPlayer.getItemList()
	
	for item in $items.get_children():
		item.visible=false
		
	
	
	var	i = 0
	for itemLoop in itemList:
		var inventoryItem=GlobalItems.getInventoryNameById(itemLoop)
		
		print("items/"+inventoryItem)
		
		var node= get_node("items/"+inventoryItem)
		node.visible=true
		
		node.global_transform.origin=Vector3(2.5*i,1,-3)
		
		i+=1
	
	if itemList.size()==0:
		$empty.visible=true
	else:
		$empty.visible=false
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _physics_process(delta):
	
	var vector=Vector3.ZERO
	
	pocessInput()
	
	if up:
		vector=Vector3(0,speed,0)
	if down:
		vector=Vector3(0,-speed,0)
	if left:
		vector=Vector3(speed,0,0)
	if right:
		vector=Vector3(-speed,0,0)
	
	if Input.is_action_just_pressed("ui_accept"):
		pass
	if Input.is_action_just_pressed("ui_cancel"):
		pushButtonB()
		pass
		
	vector*=delta
	
	$items.translate(vector)
	
func pocessInput():
	resetKeys()
	if Input.is_action_pressed("ui_right"):
		right=true
		useTouch=false
	if Input.is_action_pressed("ui_left"):
		left=true
		useTouch=false
	if Input.is_action_pressed("ui_down"):
		down=true
		useTouch=false
	if Input.is_action_pressed("ui_up"):
		up=true
		useTouch=false
	if Input.is_action_pressed("ui_page_up"):
		pageUp=true
		useTouch=false
	if Input.is_action_pressed("ui_page_down"):
		pageDown=true
		useTouch=false
		
 
func pushButtonB():
	get_tree().change_scene("res://flat.tscn")


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
		
	left=false
	right=false
	up=false
	down=false

func _on_navigation_pushButtonB():
	pushButtonB()
	pass # Replace with function body.
