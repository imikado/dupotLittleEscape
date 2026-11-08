extends Node3D

#hot water running from the bathroom tap (origin: end of the spout): the stream and the steam rising
#from the basin. showWater(false): at once (state restored when the scene is loaded)

const START_DURATION=0.25
const STOP_DURATION=0.25
#a scale of 0 is not invertible
const MIN_SCALE=0.001

#from the spout to the bottom of the basin
@export var length: float=0.28

var tween=null

func _ready():
	$stream/mesh.mesh.height=length
	$stream/mesh.position.y=-length/2
	$steam.position.y=-length
	$stream.scale.y=MIN_SCALE
	$stream.visible=false
	$steam.emitting=false

func showWater(animated_=true):
	if tween:
		tween.kill()
	$stream.position.y=0.0
	$stream.visible=true
	#restored: the steam is already there
	$steam.preprocess=0.0 if animated_ else $steam.lifetime
	$steam.emitting=true
	if !animated_:
		$stream.scale.y=1.0
		return
	tween=create_tween()
	tween.tween_property($stream,"scale:y",1.0,START_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

#the last drop falls into the basin
func hideWater():
	if tween:
		tween.kill()
	$steam.emitting=false
	tween=create_tween().set_parallel()
	tween.tween_property($stream,"position:y",-length,STOP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property($stream,"scale:y",MIN_SCALE,STOP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func(): $stream.visible=false)
