extends SubViewportContainer

#interactive: the player can rotate (drag / arrows) and zoom (wheel / page up-down)
@export var interactive: bool=false

const DEFAULT_DISTANCE=2.0
const MIN_DISTANCE=0.7
const MAX_DISTANCE=4.0
const ROTATE_SPEED=2.0
const MOUSE_ROTATE_SPEED=0.01

var distance=DEFAULT_DISTANCE

func _ready():
	mouse_filter=Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE

func setItem(id_):
	var holder=$SubViewport/pivot/holder
	for child in holder.get_children():
		child.queue_free()

	var item=GlobalItems.getItem(id_)
	var model=load(item.scene).instantiate()
	holder.add_child(model)

	if item.has("material"):
		var material=load(item.material)
		for mesh in getMeshes(model):
			mesh.set_surface_override_material(0,material)

	#center the model and scale it to fit a unit cube
	holder.transform=Transform3D()
	var aabb=null
	for mesh in getMeshes(model):
		var meshAabb=getTransformInHolder(mesh,holder) * mesh.get_aabb()
		aabb=meshAabb if aabb==null else aabb.merge(meshAabb)
	if aabb:
		var size=max(aabb.size.x,max(aabb.size.y,aabb.size.z))
		var scale_=1.0/size if size>0 else 1.0
		holder.scale=Vector3.ONE*scale_
		holder.position=-aabb.get_center()*scale_

	resetView()

func getMeshes(node_):
	var meshes=node_.find_children("*","MeshInstance3D",true,false)
	if node_ is MeshInstance3D:
		meshes.append(node_)
	return meshes

#local transforms only: the viewer may not be in the scene tree yet
func getTransformInHolder(node_,holder_):
	var result=Transform3D()
	var node=node_
	while node and node!=holder_:
		result=node.transform * result
		node=node.get_parent()
	return result

func resetView():
	#slightly from above, so flat items (post-it, paper) can be read
	$SubViewport/pivot.rotation_degrees=Vector3(50,-20,0)
	distance=DEFAULT_DISTANCE
	updateCamera()

func updateCamera():
	$SubViewport/Camera3D.position=Vector3(0,0,distance)

func rotateItem(x_,y_):
	var pivot=$SubViewport/pivot
	pivot.rotate(Vector3.UP,y_)
	pivot.rotate(Vector3.RIGHT,x_)

func zoom(factor_):
	distance=clamp(distance*factor_,MIN_DISTANCE,MAX_DISTANCE)
	updateCamera()

func _gui_input(event):
	if !interactive:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		rotateItem(event.relative.y*MOUSE_ROTATE_SPEED,event.relative.x*MOUSE_ROTATE_SPEED)
		accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom(0.9)
			accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom(1.1)
			accept_event()

func _process(delta):
	if !interactive or !is_visible_in_tree():
		return
	var x=0.0
	var y=0.0
	if Input.is_action_pressed("ui_left"):
		y-=1
	if Input.is_action_pressed("ui_right"):
		y+=1
	if Input.is_action_pressed("ui_up"):
		x-=1
	if Input.is_action_pressed("ui_down"):
		x+=1
	if x!=0 or y!=0:
		rotateItem(x*ROTATE_SPEED*delta,y*ROTATE_SPEED*delta)
	if Input.is_action_pressed("ui_page_up"):
		zoom(1.0-delta)
	if Input.is_action_pressed("ui_page_down"):
		zoom(1.0+delta)
