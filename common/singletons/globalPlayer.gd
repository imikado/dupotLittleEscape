extends Node

#an item was picked up (the "item found" popup)
signal itemAdded(item_)
#an item was used (a key unlocked a door: the "item used" popup)
signal itemUsed(item_)

var itemList=[]
var savedPosition=Vector3.ZERO
var savedCameraPosition=Vector3.ZERO

#items
func addItem(item_):
	itemList.append(item_)
	itemAdded.emit(item_)

func getItemList():
	return itemList
	
func useItem(item_):
	itemUsed.emit(item_)

func removeItem(item_):
	pass
	
func hasItem(id_):
	return itemList.has(id_)

#positions
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
