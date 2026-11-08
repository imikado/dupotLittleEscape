extends Node3D

#hot water: steam covers the mirror, then the clue written on it shows up; both fade away when the
#water is turned off. showHotWater(false): at once (state restored when the scene is loaded)

const STEAM_DURATION=2.5
const CLUE_DELAY=1.2
const CLUE_DURATION=1.5
const HIDE_DURATION=1.5

var steam=0.0
var clue=0.0
var tween=null

func _ready():
	setSteam(0.0)
	setClue(0.0)

func showHotWater(animated_=true):
	$steam.visible=true
	$MiroirClue.visible=true
	if tween:
		tween.kill()
	if !animated_:
		setSteam(1.0)
		setClue(1.0)
		return
	tween=create_tween().set_parallel()
	tween.tween_method(setSteam,steam,1.0,STEAM_DURATION*(1.0-steam)).set_trans(Tween.TRANS_SINE)
	tween.tween_method(setClue,clue,1.0,CLUE_DURATION*(1.0-clue)).set_delay(CLUE_DELAY)

func hideHotWater(animated_=true):
	if tween:
		tween.kill()
	if !animated_:
		setSteam(0.0)
		setClue(0.0)
		return
	tween=create_tween().set_parallel()
	tween.tween_method(setSteam,steam,0.0,HIDE_DURATION*steam).set_trans(Tween.TRANS_SINE)
	tween.tween_method(setClue,clue,0.0,HIDE_DURATION*clue*0.6)

func setSteam(amount_):
	steam=amount_
	$steam.material_override.set_shader_parameter("amount",amount_)
	$steam.visible=amount_>0.0

func setClue(amount_):
	clue=amount_
	$MiroirClue.material_override.set_shader_parameter("amount",amount_)
	$MiroirClue.visible=amount_>0.0
