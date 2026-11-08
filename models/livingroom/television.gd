extends StaticBody3D

var defaultProps={
	"channel":""
}
var props={}

var scene=null
var object=null

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
	elif props.channel!="":
		#wrong channel: show it, so the player knows the code was read but is not the right one
		$channelKO/SubViewport/Label.text="CH "+props.channel+"\n"+tr("TV_NO_SIGNAL")
		$channelKO/SubViewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		$channelKO.visible=true
