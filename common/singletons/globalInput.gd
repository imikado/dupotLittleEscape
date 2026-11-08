extends Node

#keyboard keys of the game actions: shown in the menu and in the hints, the player can remap them
#(settings menu), they are saved in the settings file. Gamepad events of the actions are kept.
#Keys are physical keys (position on the keyboard): W A S D are Z Q S D on an AZERTY keyboard, the
#names shown are the ones of the player's keyboard layout.

signal keysChanged

const Settings=preload("res://common/singletons/settings.gd")

#remappable actions in display order: label and placeholder used in the hint texts ({up}, {accept}...)
const ACTIONS=[
	{"action":"ui_up","name":"KEYS_FORWARD","placeholder":"up"},
	{"action":"ui_down","name":"KEYS_BACKWARD","placeholder":"down"},
	{"action":"ui_left","name":"KEYS_LEFT","placeholder":"left"},
	{"action":"ui_right","name":"KEYS_RIGHT","placeholder":"right"},
	{"action":"ui_accept","name":"KEYS_ACTION","placeholder":"accept"},
	{"action":"ui_cancel","name":"KEYS_BACK","placeholder":"cancel"},
	{"action":"inventory","name":"KEYS_INVENTORY","placeholder":"inventory"},
]

#keys kept by the game: pause menu and fullscreen
const RESERVED_KEYS=[KEY_ESCAPE,KEY_F11]

#short names (translated) instead of the engine names
const KEY_NAMES={
	KEY_UP:"↑",
	KEY_DOWN:"↓",
	KEY_LEFT:"←",
	KEY_RIGHT:"→",
	KEY_PAGEUP:"Page↑",
	KEY_PAGEDOWN:"Page↓",
	KEY_ENTER:"KEY_ENTER",
	KEY_KP_ENTER:"KEY_ENTER",
	KEY_SPACE:"KEY_SPACE",
	KEY_BACKSPACE:"KEY_BACKSPACE",
	KEY_TAB:"KEY_TAB",
	KEY_SHIFT:"KEY_SHIFT",
	KEY_CTRL:"KEY_CTRL",
	KEY_DELETE:"KEY_DELETE",
}

#settings file: the saved keys are physical keys (older versions saved the keys of the layout)
const PHYSICAL_KEYS_SETTING="physical"

#keys of the project, restored by resetKeys()
var defaultKeys={}

func _ready():
	if !InputMap.has_action("inventory"):
		InputMap.add_action("inventory")
		addKey("inventory",KEY_I)
		var button=InputEventJoypadButton.new()
		button.button_index=JOY_BUTTON_Y
		InputMap.action_add_event("inventory",button)
	for item in ACTIONS:
		defaultKeys[item.action]=getKeys(item.action)
	loadKeys()

func getKeys(action_):
	var keys=[]
	for event in InputMap.action_get_events(action_):
		if event is InputEventKey:
			keys.append(event.physical_keycode if event.physical_keycode!=KEY_NONE else event.keycode)
	return keys

func setKeys(action_,keys_):
	for event in InputMap.action_get_events(action_):
		if event is InputEventKey:
			InputMap.action_erase_event(action_,event)
	for key in keys_:
		addKey(action_,key)

func addKey(action_,key_):
	var event=InputEventKey.new()
	event.physical_keycode=key_
	InputMap.action_add_event(action_,event)

func isReserved(key_):
	return RESERVED_KEYS.has(key_)

#the key (of the layout, as pressed) replaces the keys of the action; if another action used it, that
#action gets the old keys (the two actions swap)
func remap(action_,key_):
	key_=getPhysicalKey(key_)
	var oldKeys=getKeys(action_)
	for item in ACTIONS:
		if item.action==action_:
			continue
		var keys=getKeys(item.action)
		if keys.has(key_):
			keys.erase(key_)
			if keys.is_empty():
				keys=oldKeys
			setKeys(item.action,keys)
	setKeys(action_,[key_])
	saveKeys()

func resetKeys():
	for item in ACTIONS:
		setKeys(item.action,defaultKeys[item.action])
	saveKeys()

func saveKeys():
	var values={}
	for item in ACTIONS:
		values[item.action]=getKeys(item.action)
	values[PHYSICAL_KEYS_SETTING]=true
	Settings.setValues("keys",values)
	keysChanged.emit()

func loadKeys():
	#first launch: the keys of the project
	var settings=Settings.open()
	if settings==null:
		return
	var physical=settings.get_value("keys",PHYSICAL_KEYS_SETTING,false)
	for item in ACTIONS:
		if !settings.has_section_key("keys",item.action):
			continue
		var keys=settings.get_value("keys",item.action)
		if keys is Array and !keys.is_empty():
			if !physical:
				keys=keys.map(getPhysicalKey)
			setKeys(item.action,keys)

	#older versions: the new default keys (W A S D) are added when no action uses them
	if settings.has_section("keys") and !physical:
		for item in ACTIONS:
			for key in defaultKeys[item.action]:
				if !isUsed(key):
					addKey(item.action,key)
		saveKeys()

func isUsed(key_):
	for item in ACTIONS:
		if getKeys(item.action).has(key_):
			return true
	return false

#display servers that know the keyboard layout (not the web or headless ones: physical key = key)
const LAYOUT_DISPLAY_SERVERS=["Windows","macOS","X11","Wayland"]

func hasLayout():
	return LAYOUT_DISPLAY_SERVERS.has(DisplayServer.get_name())

#physical key -> key of the player's keyboard layout (Z for the physical W on AZERTY)
func getLayoutKey(key_):
	if !hasLayout():
		return key_
	var key=DisplayServer.keyboard_get_keycode_from_physical(key_)
	return key if key!=KEY_NONE else key_

#key of the layout -> physical key: the printable keys move with the layout, the others
#(arrows, Enter...) do not
func getPhysicalKey(key_):
	if !hasLayout():
		return key_
	for physical in range(KEY_SPACE,KEY_ASCIITILDE+1):
		if DisplayServer.keyboard_get_keycode_from_physical(physical)==key_:
			return physical
	return key_

#name of a physical key on the player's keyboard
func getKeyName(key_):
	var key=getLayoutKey(key_)
	if KEY_NAMES.has(key):
		return tr(KEY_NAMES[key])
	return OS.get_keycode_string(key)

#all the keys of an action, ex: "Entrée / Espace"
func getActionKeysName(action_):
	var names=[]
	for key in getKeys(action_):
		var name=getKeyName(key)
		if !names.has(name):
			names.append(name)
	return " / ".join(names)

#translated text with the current keys, ex: "[{accept}] Oui" -> "[Entrée / Espace] Oui"
func formatText(text_):
	var placeholders={}
	for item in ACTIONS:
		placeholders[item.placeholder]=getActionKeysName(item.action)
	return tr(text_).format(placeholders)
