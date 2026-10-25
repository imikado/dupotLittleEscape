extends Node

#cartoon rendering, applied when nodes enter the tree (the scenes keep their original materials):
# - every mesh gets a toon material (flat color bands, no engine lighting)
# - every 3D camera gets a full screen quad drawing the outlines

const TOON_SHADER=preload("res://materials/toon/toon.gdshader")
#outlines: normal + depth based (Forward+), depth only for the Compatibility renderer (Web)
#loaded at runtime: the Forward+ version does not compile in Compatibility
const OUTLINE_SHADER_PATH="res://materials/toon/outline.gdshader"
const OUTLINE_SHADER_COMPATIBILITY_PATH="res://materials/toon/outline_compatibility.gdshader"

const DEFAULT_COLOR=Color(0.8,0.8,0.8)
const OUTLINE_NODE="toonOutline"

#cartoon palette: original material path -> new color (materials not listed keep their color)
#remove an entry to get the original color back
const PALETTE={
	"res://materials/cloth.tres":Color(0.98,0.95,0.88),
	"res://materials/wood.tres":Color(0.78,0.49,0.30),
	"res://materials/wood2.tres":Color(0.96,0.71,0.42),
	"res://materials/red_cloth.tres":Color(0.96,0.43,0.40),
	"res://materials/metal.tres":Color(0.72,0.80,0.88),
	"res://materials/blue_shape.tres":Color(0.38,0.78,0.86),
	"res://materials/wall.tres":Color(0.40,0.52,0.90),
	"res://materials/black.tres":Color(0.14,0.15,0.24),
	"res://materials/green.tres":Color(0.36,0.82,0.40),
	"res://ressources/Material_001.material":Color(1.0,0.80,0.18),
	"res://ressources/wood.material":Color(0.96,0.93,0.86),
	"res://ressources/carpetWhite.material":Color(0.98,0.95,0.88),
}

#rooms as world rects (x,z), split in the middle of the separating walls
const ROOMS={
	"bedroom":Rect2(-100,-100,103.925,102.525),
	"bathroom":Rect2(-100,2.525,103.925,100),
	"livingroom":Rect2(3.925,-100,12.675,200),
	"kitchen":Rect2(16.6,-100,100,200),
}
const WALL_COLORS={
	"bedroom":Color(0.84,0.79,0.96),
	"bathroom":Color(0.64,0.87,0.88),
	"livingroom":Color(0.78,0.91,0.74),
	"kitchen":Color(1.0,0.91,0.66),
}
const FLOOR_COLORS={
	"bedroom":Color(0.93,0.80,0.64),
	"bathroom":Color(0.84,0.90,0.94),
	"livingroom":Color(0.90,0.84,0.76),
	"kitchen":Color(0.93,0.66,0.52),
}
#per node overrides in the flat: node name -> {original material path: color or room colors}
const NODE_PALETTE={
	"wall":{"res://materials/wall.material":WALL_COLORS},
	"wallDoorway":{"res://materials/wall.material":WALL_COLORS},
	"ground":{"res://materials/cloth.tres":FLOOR_COLORS},
	"ceiling":{"res://materials/cloth.tres":Color(1.0,0.98,0.94)},
}
#zoom scenes: floor and wall planes without material -> room colors
const ZOOM_BACKGROUNDS={
	"res://zooms/bathroom_secretBox.tscn":{"MeshInstance3D":FLOOR_COLORS.bathroom,"MeshInstance2":WALL_COLORS.bathroom},
	"res://zooms/kitchen_secretBox.tscn":{"MeshInstance3D":FLOOR_COLORS.kitchen,"MeshInstance2":WALL_COLORS.kitchen},
	"res://zooms/livingroom_chessBoard.tscn":{"MeshInstance3D":WALL_COLORS.livingroom,"MeshInstance2":WALL_COLORS.livingroom},
}

var enabled=true
var outlineMaterial=null
#original material -> converted material
var cache={}

#_enter_tree and not _ready: at startup the main scene enters the tree before the autoloads are ready
func _enter_tree():
	outlineMaterial=ShaderMaterial.new()
	var compatibility=RenderingServer.get_current_rendering_method()=="gl_compatibility"
	outlineMaterial.shader=load(OUTLINE_SHADER_COMPATIBILITY_PATH if compatibility else OUTLINE_SHADER_PATH)
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node_):
	if !enabled:
		return
	if node_ is MeshInstance3D and node_.name!=OUTLINE_NODE:
		applyToon(node_)
	elif node_ is Camera3D:
		addOutline.call_deferred(node_)

func applyToon(mesh_):
	if mesh_.mesh==null or mesh_.has_meta("no_toon"):
		return

	if mesh_.material_override:
		mesh_.material_override=convertMaterial(mesh_.material_override)
		return

	if mesh_.owner and ZOOM_BACKGROUNDS.has(mesh_.owner.scene_file_path):
		var color=ZOOM_BACKGROUNDS[mesh_.owner.scene_file_path].get(String(mesh_.name))
		if color:
			for surface in mesh_.mesh.get_surface_count():
				mesh_.set_surface_override_material(surface,convertNodeMaterial(null,color))
			return

	var overrides=NODE_PALETTE.get(String(mesh_.name),{})
	for surface in mesh_.mesh.get_surface_count():
		var material=mesh_.get_active_material(surface)
		var converted=null
		if material and overrides.has(material.resource_path):
			converted=convertNodeMaterial(material,overrides[material.resource_path])
		else:
			converted=convertMaterial(material)
		if converted:
			mesh_.set_surface_override_material(surface,converted)

func convertMaterial(material_):
	if cache.has(material_):
		return cache[material_]

	var converted=null
	if material_==null:
		converted=createToon(DEFAULT_COLOR,null)
	elif material_ is StandardMaterial3D:
		if material_.albedo_texture is ViewportTexture:
			#text displayed through a viewport: keep it, just make it readable
			converted=material_.duplicate()
			converted.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		elif material_.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
			converted=material_
		else:
			converted=createToon(getColor(material_,material_.albedo_color),material_.albedo_texture)
	elif material_ is ShaderMaterial and material_.shader!=TOON_SHADER:
		#materials/*.tres: converted Godot 3 spatial materials (albedo + texture_albedo)
		var color=material_.get_shader_parameter("albedo")
		if color is Color:
			converted=createToon(getColor(material_,color),material_.get_shader_parameter("texture_albedo"))
		else:
			converted=material_
	else:
		converted=material_

	cache[material_]=converted
	return converted

func getColor(material_,color_):
	return PALETTE.get(material_.resource_path,color_)

#node override: one color, or one color per room (tinted by world position in the shader)
func convertNodeMaterial(material_,colors_):
	var key=[material_,colors_] if material_ else colors_
	if cache.has(key):
		return cache[key]
	var converted=null
	if colors_ is Color:
		converted=createToon(colors_,null)
	else:
		#outside the rooms: the global palette
		converted=convertMaterial(material_).duplicate()
		var rects=[]
		var colors=[]
		for room in colors_:
			var rect=ROOMS[room]
			rects.append(Vector4(rect.position.x,rect.position.y,rect.end.x,rect.end.y))
			var color=colors_[room].srgb_to_linear()
			colors.append(Vector4(color.r,color.g,color.b,1.0))
		converted.set_shader_parameter("zone_count",rects.size())
		converted.set_shader_parameter("zone_rects",rects)
		converted.set_shader_parameter("zone_colors",colors)
	cache[key]=converted
	return converted

func createToon(color_,texture_):
	var material=ShaderMaterial.new()
	material.shader=TOON_SHADER
	material.set_shader_parameter("albedo",color_)
	if texture_:
		material.set_shader_parameter("texture_albedo",texture_)
	return material

func addOutline(camera_):
	if !is_instance_valid(camera_) or camera_.has_node(OUTLINE_NODE):
		return
	var quad=QuadMesh.new()
	quad.size=Vector2(2,2)
	var outline=MeshInstance3D.new()
	outline.name=OUTLINE_NODE
	outline.mesh=quad
	outline.material_override=outlineMaterial
	#always drawn: the vertex shader covers the whole screen
	outline.extra_cull_margin=16384
	outline.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera_.add_child(outline)
