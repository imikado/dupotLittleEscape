extends Control

#settings screen: keyboard keys remapping. Click a key button, then press the new key
#(Escape cancels, reserved keys are refused)

signal closed

@onready var grid=%keys

#action waiting for its new key
var waitingAction=null
var buttons={}

func _ready():
	visible=false
	for item in GlobalInput.ACTIONS:
		var label=Label.new()
		label.text=item.name
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(label)

		var button=Button.new()
		button.custom_minimum_size=Vector2(170,36)
		button.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(startWaiting.bind(item.action))
		grid.add_child(button)
		buttons[item.action]=button
	GlobalInput.keysChanged.connect(refresh)

func open():
	refresh()
	visible=true
	buttons[GlobalInput.ACTIONS[0].action].grab_focus.call_deferred()

func close():
	stopWaiting()
	visible=false
	closed.emit()

func refresh():
	for action in buttons:
		buttons[action].text=GlobalInput.getActionKeysName(action)

func startWaiting(action_):
	stopWaiting()
	waitingAction=action_
	buttons[action_].text=tr("SETTINGS_PRESS_KEY")

func stopWaiting():
	waitingAction=null
	refresh()

#_input: the key must not reach the buttons (focus, ui_accept) nor the pause menu (Escape)
func _input(event):
	if !visible or !(event is InputEventKey) or !event.pressed or event.echo:
		return
	var key=event.keycode if event.keycode!=KEY_NONE else event.physical_keycode

	if waitingAction==null:
		if key==KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	if key==KEY_ESCAPE:
		stopWaiting()
	elif GlobalInput.isReserved(key):
		buttons[waitingAction].text=tr("SETTINGS_RESERVED_KEY")
	else:
		var button=buttons[waitingAction]
		GlobalInput.remap(waitingAction,key)
		stopWaiting()
		button.grab_focus()

func _on_reset_pressed():
	stopWaiting()
	GlobalInput.resetKeys()

func _on_back_pressed():
	close()
