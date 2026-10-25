extends SceneTree
# Rend le fond du menu (ui/menu/background.png) : la chambre en cel-shading,
# sans l'interface du jeu.
#
# Usage (fenêtre visible : le rendu a besoin d'un écran) :
#   godot --path . -s tools/capture/menu_background.gd [-- position regard sortie]
#   position : "x,y,z" de l'œil, regard : "x,y,z" du point regardé

const FLAT="res://flat.tscn"
const SIZE=Vector2i(2048,1200)
const EYE=Vector3(3.2,1.6,-2.6)
const LOOK=Vector3(-3.0,1.0,1.4)
const OUTPUT="res://ui/menu/background.png"
# images rendues avant la capture (chargement, contours, interpolation)
const WAIT_FRAMES=20

var _frame:=0
var _loading:=false
var _eye:=EYE
var _look:=LOOK
var _output:=OUTPUT

func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.size()>=2:
		_eye=_vector(args[0])
		_look=_vector(args[1])
	if args.size()>=3:
		_output=args[2]

func _process(_delta):
	# pas dans _initialize : les singletons (ToonStyle, GlobalGame) ne sont
	# pas encore prêts, la scène resterait grise
	if current_scene==null or current_scene.scene_file_path!=FLAT:
		if !_loading:
			_loading=true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(SIZE)
			change_scene_to_file(FLAT)
		return false
	_frame+=1
	if _frame==1:
		_prepare()
	elif _frame==WAIT_FRAMES:
		var image=root.get_texture().get_image()
		var path=_output if _output.is_absolute_path() else ProjectSettings.globalize_path(_output)
		image.save_png(path)
		print(path)
		quit()
	return false

func _prepare():
	# pas d'interface du jeu (HUD, inventaire, contrôles tactiles)
	for node in current_scene.find_children("*","CanvasLayer",true,false):
		node.visible=false
	for node in root.get_children():
		if node is CanvasLayer:
			node.visible=false

	var player=current_scene.get_node("Player")
	player.set_physics_process(false)
	player.set_process_input(false)
	player.global_position=Vector3(_eye.x,0.0,_eye.z)
	player.look_at(Vector3(_look.x,0.0,_look.z),Vector3.UP)
	var camera=player.get_node("XROrigin3D/Camera3D")
	camera.global_position.y=_eye.y
	var distance=Vector2(_look.x-_eye.x,_look.z-_eye.z).length()
	camera.rotation.x=atan2(_look.y-_eye.y,distance)
	player.reset_physics_interpolation()

func _vector(text_:String)->Vector3:
	var parts=text_.split(",")
	return Vector3(float(parts[0]),float(parts[1]),float(parts[2]))
