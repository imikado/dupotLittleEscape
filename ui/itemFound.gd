extends CanvasLayer

#"found it!" popup when an item is picked up: pop-in with confetti, the item turns, then the card
#flies to the inventory button (top right) and the button bounces (stored signal)
#"used!" popup when an item is used (a key unlocks a door): the card comes out of the inventory
#button, the key turns like in a lock, then the card vanishes

signal stored

const POP_DURATION=0.4
const DISPLAY_TIME=1.8
const FLY_DURATION=0.45
const SPIN_SPEED=1.6
const TURN_DURATION=0.5
const USED_DISPLAY_TIME=0.9
#center of the inventory button (top right corner)
const INVENTORY_OFFSET=Vector2(-108,36)

@onready var center=$center
@onready var viewer=$center/window/content/itemViewer

var tween=null
#used popup: the key turns once instead of spinning
var spinning=true
var turnAngle=0.0

func _ready():
	GlobalPlayer.itemAdded.connect(showItem)
	GlobalPlayer.itemUsed.connect(showUsedItem)

func _process(delta):
	if visible and spinning:
		viewer.rotateItem(0.0,SPIN_SPEED*delta)

func showItem(id_):
	setWindow(id_,"ITEM_FOUND",true)
	spinning=true
	popIn()

func showUsedItem(id_):
	setWindow(id_,"ITEM_USED",false)
	spinning=false
	turnAngle=0.0
	popOut()

func setWindow(id_,title_,hint_):
	viewer.setItem(id_)
	$center/window/content/title.text=title_
	$center/window/content/name.text=GlobalItems.getItem(id_).name
	$center/window/content/hint.visible=hint_
	$center/window/content/hint.text=GlobalInput.formatText("ITEM_FOUND_HINT")
	if tween:
		tween.kill()
	center.position=Vector2.ZERO
	center.scale=Vector2.ONE
	center.modulate.a=0.0
	visible=true

func popIn():
	#the window is centered in its container, whose size comes from its anchors
	var windowCenter=center.size/2
	center.pivot_offset=windowCenter
	center.scale=Vector2(0.5,0.5)

	$confetti.position=windowCenter
	$confetti.restart()

	tween=create_tween()
	tween.tween_property(center,"scale",Vector2.ONE,POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(center,"modulate:a",1.0,POP_DURATION*0.5)
	tween.tween_interval(DISPLAY_TIME)

	#into the inventory
	var target=Vector2(center.get_viewport_rect().size.x,0)+INVENTORY_OFFSET
	tween.tween_property(center,"position",target-windowCenter,FLY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(center,"scale",Vector2(0.1,0.1),FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(center,"modulate:a",0.0,FLY_DURATION).set_delay(FLY_DURATION*0.5)
	tween.tween_callback(hideItem)

#the reverse of popIn: out of the inventory, the key turns, then the card vanishes
func popOut():
	var windowCenter=center.size/2
	center.pivot_offset=windowCenter
	var start=Vector2(center.get_viewport_rect().size.x,0)+INVENTORY_OFFSET
	center.position=start-windowCenter
	center.scale=Vector2(0.1,0.1)

	$confetti.position=windowCenter

	tween=create_tween()
	tween.tween_property(center,"position",Vector2.ZERO,FLY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(center,"scale",Vector2.ONE,FLY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(center,"modulate:a",1.0,FLY_DURATION*0.5)
	#a quarter turn, like in a lock
	tween.tween_method(turnKey,0.0,PI/2,TURN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback($confetti.restart)
	tween.tween_interval(USED_DISPLAY_TIME)
	tween.tween_property(center,"scale",Vector2(1.2,1.2),POP_DURATION*0.5)
	tween.parallel().tween_property(center,"modulate:a",0.0,POP_DURATION*0.5)
	tween.tween_callback(func(): visible=false)

func turnKey(angle_):
	viewer.rotateItem(0.0,angle_-turnAngle)
	turnAngle=angle_

func hideItem():
	visible=false
	stored.emit()
