extends RefCounted

#settings file of the player (language, touch, sound, keys), shared by the singletons
#not an autoload: const Settings=preload("res://common/singletons/settings.gd")
#Settings.getValue("game","sound",true)

const FILE="user://settings.cfg"

#the settings file, or null when it does not exist yet (first launch) or cannot be read
static func open():
	var settings=ConfigFile.new()
	if settings.load(FILE)!=OK:
		return null
	return settings

static func getValue(section_,key_,default_):
	var settings=ConfigFile.new()
	settings.load(FILE)
	return settings.get_value(section_,key_,default_)

static func setValue(section_,key_,value_):
	setValues(section_,{key_:value_})

#several keys of a section with one save
static func setValues(section_,values_):
	var settings=ConfigFile.new()
	#first launch: no file yet, it is created
	settings.load(FILE)
	for key in values_:
		settings.set_value(section_,key,values_[key])
	settings.save(FILE)
