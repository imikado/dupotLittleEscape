extends StaticBody3D

var defaultProps={
	"channel":"0"
}
var props={}

var scene=null
var object=null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init(scene_,object_):
	scene=scene_
	object=object_

	props=GlobalRoom.getStateForRoomOr(scene,object,defaultProps)
	
	refreshState()

func refreshState():
	$channelOK.visible=false
	$channelKO.visible=false
	
	if props.channel=="2153":
		$channelOK.visible=true
	elif props.channel!="0":
		#wrong channel: show it, so the player knows the code was read but is not the right one
		$channelKO/SubViewport/Label.text="CH "+props.channel+"\n"+tr("TV_NO_SIGNAL")
		$channelKO/SubViewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		$channelKO.visible=true
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
