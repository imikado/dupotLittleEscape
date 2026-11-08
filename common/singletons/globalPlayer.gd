extends Node

#an item was picked up (the "item found" popup)
signal itemAdded(item_)
#an item was used (a key unlocked a door: the "item used" popup)
signal itemUsed(item_)

var itemList=[]
#items already used (keys that unlocked their door): greyed in the inventory
var usedItemList=[]
var savedPosition=Vector3.ZERO
var savedCameraPosition=Vector3.ZERO
#a game was started and is not finished yet (main menu: "continue")
var gameInProgress=false

#progress kept between two launches of the game (not in settings.cfg: separate concern)
const SAVE_PATH="user://savegame.cfg"

#rooms state read from the save, taken by GlobalRoom (autoload after this one)
var loadedRoomsData={}

func _ready():
	loadGame()

func _notification(what_):
	#window closed / mobile app sent to background: keep the current position
	if what_==NOTIFICATION_WM_CLOSE_REQUEST or what_==NOTIFICATION_APPLICATION_PAUSED:
		saveCurrentScene()

#new game: empty inventory, player at the start position, furniture and doors back to their
#default state
func newGame():
	itemList=[]
	usedItemList=[]
	savedPosition=Vector3.ZERO
	savedCameraPosition=Vector3.ZERO
	GlobalRoom.reset()
	SceneTransition.clearKeptScene()
	gameInProgress=true
	saveGame()

#the exit door is open
func finishGame():
	gameInProgress=false
	#nothing left to continue
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func isGameInProgress():
	return gameInProgress

#items
func addItem(item_):
	itemList.append(item_)
	saveGame()
	itemAdded.emit(item_)

func getItemList():
	return itemList

func useItem(item_):
	if !usedItemList.has(item_):
		usedItemList.append(item_)
		saveGame()
	itemUsed.emit(item_)

func isItemUsed(id_):
	return usedItemList.has(id_)

func hasItem(id_):
	return itemList.has(id_)

#positions (not written to the disk here: the caller saves both, then calls saveGame)
func savePosition(position_):
	savedPosition=position_

func shouldLoadPosition():
	if savedPosition!=Vector3.ZERO:
		return true
	return false

func getPosition():
	return savedPosition

func saveCameraPosition(position_):
	savedCameraPosition=position_

func getCameraPosition():
	return savedCameraPosition

#save file
func saveGame():
	#finished game or no game started: nothing to continue
	if !gameInProgress:
		return
	var config=ConfigFile.new()
	config.set_value("game","inProgress",true)
	config.set_value("player","itemList",itemList)
	config.set_value("player","usedItemList",usedItemList)
	config.set_value("player","position",savedPosition)
	config.set_value("player","camera",savedCameraPosition)
	config.set_value("rooms","data",GlobalRoom.roomsData)
	var error=config.save(SAVE_PATH)
	if error!=OK:
		push_warning("savegame not written: "+error_string(error))

func loadGame():
	var config=ConfigFile.new()
	if config.load(SAVE_PATH)!=OK:
		return
	if !config.get_value("game","inProgress",false):
		return
	itemList=config.get_value("player","itemList",[])
	usedItemList=config.get_value("player","usedItemList",[])
	savedPosition=config.get_value("player","position",Vector3.ZERO)
	savedCameraPosition=config.get_value("player","camera",Vector3.ZERO)
	loadedRoomsData=config.get_value("rooms","data",{})
	gameInProgress=true

#the rooms state from the save, only once (a new game starts from an empty one)
func takeLoadedRoomsData():
	var data=loadedRoomsData
	loadedRoomsData={}
	return data

#the current scene knows the player position (flat), the close-ups do not move it
func saveCurrentScene():
	var scene=get_tree().current_scene
	if scene and scene.has_method("savePlayerPosition"):
		scene.savePlayerPosition()
	else:
		saveGame()
