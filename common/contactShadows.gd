extends Node3D

#soft contact shadows (the cartoon rendering has no engine lighting): a transparent quad on the floor
#under each furniture of the parent room standing on the floor, built when the room is loaded
#a furniture is an instanced scene: its meshes are grouped by owner (the chairs of a table get their
#own shadow), the meshes of the room scene itself (skirting boards, rugs) get none

const SHADER=preload("res://common/contactShadow.gdshader")
#furniture standing on the floor: bottom of its meshes below this height
const FLOOR_MARGIN=0.15
#flat things get no shadow
const MIN_HEIGHT=0.2
#soft edge around the footprint
const BLUR=0.2
#above the floor and the rugs: no z-fighting
const HEIGHT=0.012

#room interior on the floor (x,z): the shadows do not go under the walls into the next room
@export var bounds: Rect2

var quad=null

func _ready():
	var material=ShaderMaterial.new()
	material.shader=SHADER
	material.set_shader_parameter("blur",BLUR)
	material.set_shader_parameter("clip_rect",Vector4(bounds.position.x,bounds.position.y,bounds.end.x,bounds.end.y))

	quad=PlaneMesh.new()
	quad.size=Vector2.ONE

	var footprints={}
	collectFootprints(get_parent(),footprints)
	for aabb in footprints.values():
		if aabb.position.y<FLOOR_MARGIN and aabb.size.y>=MIN_HEIGHT:
			addShadow(aabb,material)

func collectFootprints(node_,footprints_):
	for child in node_.get_children():
		if child==self:
			continue
		if child is MeshInstance3D and isShadowCaster(child):
			var aabb=child.global_transform*child.get_aabb()
			var furniture=getFurniture(child)
			footprints_[furniture]=aabb if !footprints_.has(furniture) else footprints_[furniture].merge(aabb)
		collectFootprints(child,footprints_)

#root of the instanced scene the mesh belongs to (the mesh itself when it is the root)
func getFurniture(mesh_):
	return mesh_ if mesh_.scene_file_path!="" else mesh_.owner

func isShadowCaster(mesh_):
	if mesh_.mesh==null or !mesh_.is_visible_in_tree() or mesh_.name==ToonStyle.OUTLINE_NODE:
		return false
	#meshes of the room scene itself
	var furniture=getFurniture(mesh_)
	return furniture!=null and furniture!=get_parent()

func addShadow(aabb_,material_):
	var shadow=MeshInstance3D.new()
	#before entering the tree: no cartoon material
	shadow.set_meta("no_toon",true)
	shadow.mesh=quad
	shadow.material_override=material_
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	var center=aabb_.get_center()
	var size=Vector3(aabb_.size.x+BLUR*2.0,1.0,aabb_.size.z+BLUR*2.0)
	shadow.global_transform=Transform3D(Basis.from_scale(size),Vector3(center.x,HEIGHT,center.z))
