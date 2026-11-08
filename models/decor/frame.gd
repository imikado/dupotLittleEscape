extends Node3D

#painting on a wall (models/decor/picture.gdshader)

#0 mountains and sun, 1 colored shapes, 2 sea and sailing boat
@export_enum("Mountains","Shapes","Sea") var style: int=0

func _ready():
	var material=$picture.material_override.duplicate()
	material.set_shader_parameter("style",style)
	material.set_shader_parameter("aspect",$picture.mesh.size.x/$picture.mesh.size.y)
	$picture.material_override=material
