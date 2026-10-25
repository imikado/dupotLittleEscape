extends Node


enum ID {
	   POSTIT,
		PAPER,
		BEDROOM_KEY,
		BATHROOM_KEY,
		KITCHEN_KEY,
		
		EXIT_KEY
	}

var itemList={

	ID.POSTIT:{
		"inventory":"postit",
		"name":"ITEM_POSTIT",
		"scene":"res://models/bedroom/postit.tscn",
	},
	ID.PAPER:{
		"inventory":"paper",
		"name":"ITEM_PAPER",
		"scene":"res://models/bedroom/paper.tscn",
	},
	ID.BEDROOM_KEY:{
		"inventory":"bedroom_key",
		"name":"ITEM_BEDROOM_KEY",
		"scene":"res://models/bedroom/bedroom_key.tscn",
	},
	ID.BATHROOM_KEY:{
		"inventory":"bathroom_key",
		"name":"ITEM_BATHROOM_KEY",
		"scene":"res://models/bedroom/bedroom_key.tscn",
		"material":"res://materials/metal.tres",
	},
	ID.KITCHEN_KEY:{
		"inventory":"kitchen_key",
		"name":"ITEM_KITCHEN_KEY",
		"scene":"res://models/bedroom/bedroom_key.tscn",
		"material":"res://materials/red_cloth.tres",
	},
	ID.EXIT_KEY:{
		"inventory":"exit_key",
		"name":"ITEM_EXIT_KEY",
		"scene":"res://models/bedroom/bedroom_key.tscn",
		"material":"res://materials/wall.tres",
	},
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func getItem(id_):
	return itemList[id_]
	
func getInventoryNameById(id_):
	return itemList.get(id_).inventory

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
