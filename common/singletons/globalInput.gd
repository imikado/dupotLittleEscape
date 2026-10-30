extends Node

#keyboard keys of the game actions: shown in the menu and in the hints, the player can remap them
#(settings menu), they are saved in the settings file. Gamepad events of the actions are kept.

signal keysChanged

const SETTINGS_FILE="user://settings.cfg"

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

#keys of the project, restored by resetKeys()
var defaultKeys={}

func _ready():
	if !InputMap.has_action("inventory"):
		InputMap.add_action("inventory")
		addKey("inventory",KEY_I)
	for item in ACTIONS:
		defaultKeys[item.action]=getKeys(item.action)
	loadKeys()

func getKeys(action_):
	var keys=[]
	for event in InputMap.action_get_events(action_):
		if event is InputEventKey:
			keys.append(event.keycode if event.keycode!=KEY_NONE else event.physical_keycode)
	return keys

func setKeys(action_,keys_):
	for event in InputMap.action_get_events(action_):
		if event is InputEventKey:
			InputMap.action_erase_event(action_,event)
	for key in keys_:
		addKey(action_,key)

func addKey(action_,key_):
	var event=InputEventKey.new()
	event.keycode=key_
	InputMap.action_add_event(action_,event)

func isReserved(key_):
	return RESERVED_KEYS.has(key_)

#the key replaces the keys of the action; if another action used it, that action gets the old keys
#(the two actions swap)
func remap(action_,key_):
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
	var settings=ConfigFile.new()
	settings.load(SETTINGS_FILE)
	for item in ACTIONS:
		settings.set_value("keys",item.action,getKeys(item.action))
	settings.save(SETTINGS_FILE)
	keysChanged.emit()

func loadKeys():
	var settings=ConfigFile.new()
	if settings.load(SETTINGS_FILE)!=OK:
		return
	for item in ACTIONS:
		if !settings.has_section_key("keys",item.action):
			continue
		var keys=settings.get_value("keys",item.action)
		if keys is Array and !keys.is_empty():
			setKeys(item.action,keys)

func getKeyName(key_):
	if KEY_NAMES.has(key_):
		return tr(KEY_NAMES[key_])
	return OS.get_keycode_string(key_)

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
