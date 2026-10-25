extends "res://common/abstracts/furniture.gd"

func _ready():
	defaultProps={
		"state":CLOSED
	}
	
func refreshState():
	if props.state==OPENED:
		openDrawer()
		
func refreshItem():
	$drawer/paper.visible=false
	$drawer/postit.visible=false
	
	if props.item==GlobalItems.ID.PAPER:
		$drawer/paper.visible=true
	if props.item==GlobalItems.ID.POSTIT:	
		$drawer/postit.visible=true
		
func openDrawer():
	$drawer.open()

func closeDrawer():
	$drawer.close()

func displayInfo():
	if props.state==CLOSED:
		showInfo("INFO_OPEN_IT")
	else:
		if props.item==GlobalItems.ID.BEDROOM_KEY:
			showInfo("INFO_TAKE_POSTIT")
		else:
			showInfo("INFO_CLOSE_IT")


func action():
	if props.state==CLOSED:
		openDrawer()
		
		props.state=OPENED
	else:
		closeDrawer()
		
		props.state=CLOSED
	
	saveProps()
		
	displayInfo()
