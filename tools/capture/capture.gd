extends SceneTree
# Visite guidée utilisée pour enregistrer le GIF de promotion et les
# screenshots (voir tools/capture/capture.sh).
#
# Lancé par Godot en mode Movie Maker (--write-movie) : le temps est fixe,
# chaque image est enregistrée, la visite est donc reproductible.
#
# Chaque plan affiche une scène pendant une durée donnée. Dans l'appartement,
# la caméra glisse d'une position à l'autre en regardant un point qui se
# déplace lui aussi (positions au sol x/z, points regardés en x/y/z).

const FLAT="res://flat.tscn"

const SHOTS=[
	{"name":"menu","scene":"res://ui/Menu.tscn","duration":3.0},
	{"name":"bedroom","scene":FLAT,"duration":6.0,
		"from":Vector2(-3.2,-1.8),"to":Vector2(-2.2,-0.6),
		"look_from":Vector3(2.0,0.8,-0.2),"look_to":Vector3(-0.9,1.4,2.2)},
	{"name":"bedroom_clock","scene":FLAT,"duration":4.0,
		"from":Vector2(-0.6,-1.2),"to":Vector2(0.4,-2.2),
		"look_from":Vector3(2.6,2.2,-3.3),"look_to":Vector3(1.1,0.9,-3.1)},
	{"name":"bathroom","scene":FLAT,"duration":5.0,
		"from":Vector2(2.0,4.0),"to":Vector2(0.4,5.0),
		"look_from":Vector3(-3.7,1.6,6.9),"look_to":Vector3(-3.8,0.6,3.3)},
	{"name":"livingroom","scene":FLAT,"duration":6.0,
		"from":Vector2(5.2,1.0),"to":Vector2(8.0,1.6),
		"look_from":Vector3(10.3,1.0,-2.3),"look_to":Vector3(10.2,0.6,5.2)},
	{"name":"livingroom_laptop","scene":FLAT,"duration":4.0,
		"from":Vector2(11.5,1.5),"to":Vector2(13.6,0.4),
		"look_from":Vector3(13.8,0.8,-1.1),"look_to":Vector3(15.0,1.0,-0.6)},
	{"name":"kitchen","scene":FLAT,"duration":6.0,
		"from":Vector2(17.3,6.2),"to":Vector2(17.6,2.0),
		"look_from":Vector3(19.2,1.2,3.6),"look_to":Vector3(19.7,1.2,-1.9)},
	{"name":"exit","scene":FLAT,"duration":3.0,
		"from":Vector2(13.5,4.0),"to":Vector2(13.5,6.4),
		"look_from":Vector3(13.5,1.3,8.7),"look_to":Vector3(13.5,1.2,8.7)},
	{"name":"closet","scene":"res://zooms/bedroom_closet.tscn","duration":3.0},
	{"name":"chessboard","scene":"res://zooms/livingroom_chessBoard.tscn","duration":3.0},
	{"name":"remote_control","scene":"res://zooms/livingroom_remoteControl.tscn","duration":3.0},
	{"name":"kitchen_secret_box","scene":"res://zooms/kitchen_secretBox.tscn","duration":3.0},
	{"name":"end","scene":"res://ui/end.tscn","duration":3.0},
]

const CAMERA_HEIGHT=1.8

var _time:=0.0
var _frame:=0
var _shot:=-1
var _shot_start:=0.0
# plans de la visite : tous, ou ceux de CAPTURE_ONLY (noms séparés par des
# espaces, dans l'ordre voulu)
var _shots=SHOTS
# capture.sh lit les plans (nom, première et dernière image) dans ce fichier
var _shots_file=null

func _initialize():
	var path=OS.get_environment("CAPTURE_SHOTS")
	if path!="":
		_shots_file=FileAccess.open(path,FileAccess.WRITE)
	var names=OS.get_environment("CAPTURE_ONLY")
	if names!="":
		_shots=[]
		for name in names.split(" ",false):
			var shot=_find_shot(name)
			if shot==null:
				printerr("Plan inconnu : %s"%name)
				quit(1)
				return
			_shots.append(shot)

func _process(delta):
	var index=_shot_at(_time)
	if index<0:
		_end_shot()
		_shot=-1
		if _shots_file:
			_shots_file.close()
			_shots_file=null
		quit()
		return false

	var shot=_shots[index]
	if index!=_shot:
		_end_shot()
		if _shot<0:
			# visite en anglais, sans modifier la langue enregistrée du joueur
			# (pas dans _initialize : GlobalGame recharge la langue à son _ready)
			TranslationServer.set_locale("en")
		_shot=index
		_shot_start=_time
		if _shots_file:
			_shots_file.store_string("%s %d"%[shot.name,_frame])
		var scene_path=current_scene.scene_file_path if current_scene else ""
		if scene_path!=shot.scene:
			change_scene_to_file(shot.scene)

	if current_scene and current_scene.scene_file_path==FLAT and shot.has("from"):
		var t=clamp((_time-_shot_start)/shot.duration,0.0,1.0)
		_place_camera(shot,smoothstep(0.0,1.0,t))

	_time+=delta
	_frame+=1
	return false

func _end_shot():
	if _shots_file and _shot>=0:
		_shots_file.store_line(" %d"%(_frame-1))

func _shot_at(time_):
	var end=0.0
	for i in _shots.size():
		end+=_shots[i].duration
		if time_<end:
			return i
	return -1

func _find_shot(name_):
	for shot in SHOTS:
		if shot.name==name_:
			return shot
	return null

func _place_camera(shot_,t_):
	var player=current_scene.get_node("Player")
	# la caméra est pilotée ici : pas de déplacement ni d'inclinaison automatique
	player.set_physics_process(false)

	var ground=shot_.from.lerp(shot_.to,t_)
	var look=shot_.look_from.lerp(shot_.look_to,t_)
	var position=Vector3(ground.x,0.0,ground.y)
	player.global_position=position
	player.look_at(Vector3(look.x,0.0,look.z),Vector3.UP)

	var camera=player.get_node("XROrigin3D/Camera3D")
	var eye=position+Vector3(0.0,CAMERA_HEIGHT,0.0)
	var distance=Vector2(look.x-eye.x,look.z-eye.z).length()
	camera.rotation.x=atan2(look.y-eye.y,distance)
	# pas d'interpolation physique entre deux positions imposées
	player.reset_physics_interpolation()
