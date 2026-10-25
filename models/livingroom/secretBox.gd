extends "res://common/abstracts/furniture.gd"

func _ready():
	defaultProps={
		"state":CLOSED
	}
	
func refreshState():
	if props.state==OPENED:
		openCover()
		
func refreshItem():
	$base/key.visible=false
	
	if props.item==GlobalItems.ID.BATHROOM_KEY:
		$base/key.visible=true
		
func openCover():
	$cover.open()

func closeCover():
	$cover.close()

func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_OPEN_IT")
	else:
		if props.item==GlobalItems.ID.BATHROOM_KEY:
			showInfo("INFO_TAKE_KEY")
		else:
			showInfo("INFO_CLOSE_IT")


func action():
	if props.state==CLOSED:
		openCover()
		
		props.state=OPENED
	else:
		closeCover()
		
		props.state=CLOSED
	
	saveProps()
		
	displayInfo()
