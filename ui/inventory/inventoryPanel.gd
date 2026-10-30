extends CanvasLayer

const ITEM_VIEWER=preload("res://ui/inventory/itemViewer.tscn")

@onready var overlay=$overlay
@onready var grid=$overlay/window/content/gridView/grid
@onready var gridView=$overlay/window/content/gridView
@onready var emptyLabel=$overlay/window/content/empty
@onready var detail=$overlay/window/content/detail
@onready var detailViewer=$overlay/window/content/detail/itemViewer
@onready var detailName=$overlay/window/content/detail/name

var selectedSlot=null
#Escape closes the panel and the player also reads it in the same frame
var closedFrame=-1

#the button bounces when a found item arrives in the inventory
const BOUNCE_SCALE=1.3
const BOUNCE_DURATION=0.5

func _ready():
	overlay.visible=false
	ItemFound.stored.connect(bounceButton)
	refreshTexts()
	GlobalInput.keysChanged.connect(refreshTexts)

#texts with the keyboard keys
func refreshTexts():
	$openButton.text=GlobalInput.formatText("INVENTORY_BUTTON")
	$overlay/window/content/detail/hint.text=GlobalInput.formatText("INVENTORY_VIEW_HINT")

func bounceButton():
	var button=$openButton
	button.pivot_offset=button.size/2
	button.scale=Vector2.ONE*BOUNCE_SCALE
	var tween=create_tween()
	tween.tween_property(button,"scale",Vector2.ONE,BOUNCE_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

#hidden while the inventory or the pause menu is open
func _process(_delta):
	$openButton.visible=!get_tree().paused

func isOpen():
	return overlay.visible

func toggle():
	if isOpen():
		close()
	else:
		open()

func open():
	if Engine.get_process_frames()==closedFrame:
		return
	GlobalAudio.play("pop")
	#the language may have changed since
	refreshTexts()
	refreshGrid()
	showGrid()
	overlay.visible=true
	get_tree().paused=true

func close():
	closedFrame=Engine.get_process_frames()
	overlay.visible=false
	get_tree().paused=false

func refreshGrid():
	selectedSlot=null
	for slot in grid.get_children():
		grid.remove_child(slot)
		slot.queue_free()

	var itemList=GlobalPlayer.getItemList()
	emptyLabel.visible=itemList.size()==0

	for id in itemList:
		grid.add_child(createSlot(id))

func createSlot(id_):
	var slot=Button.new()
	slot.custom_minimum_size=Vector2(170,170)

	var box=VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,8)
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	slot.add_child(box)

	var viewer=ITEM_VIEWER.instantiate()
	viewer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(viewer)
	viewer.setItem(id_)

	var label=Label.new()
	label.text=GlobalItems.getItem(id_).name
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)

	slot.pressed.connect(showDetail.bind(id_,slot))
	return slot

func showGrid():
	detail.visible=false
	gridView.visible=true
	var target=selectedSlot if is_instance_valid(selectedSlot) else null
	if target==null and grid.get_child_count()>0:
		target=grid.get_child(0)
	if target:
		target.grab_focus.call_deferred()
	else:
		$overlay/window/content/header/close.grab_focus.call_deferred()

func showDetail(id_,slot_):
	selectedSlot=slot_
	gridView.visible=false
	emptyLabel.visible=false
	detail.visible=true
	detailViewer.setItem(id_)
	detailName.text=GlobalItems.getItem(id_).name
	$overlay/window/content/detail/back.grab_focus.call_deferred()

func _unhandled_input(event):
	if event.is_action_pressed("inventory") and !event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()
		return

	if !isOpen():
		return

	#Escape is handled here before the pause menu (autoload) receives it
	var escape=event is InputEventKey and event.pressed and !event.echo and event.keycode==KEY_ESCAPE
	if escape or event.is_action_pressed("ui_cancel"):
		if detail.visible:
			showGrid()
		else:
			close()
		get_viewport().set_input_as_handled()

func _on_back_pressed():
	showGrid()
