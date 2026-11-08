extends "res://zooms/zoom.gd"

const ROTATE_SPEED=80

#letters and digits engraved on the border: raised above the board (model space), drawn in a
#light color so they stand out (they share the material of the dark squares)
const COORDINATES_HEIGHT=1.05
const COORDINATES_COLOR=Color(0.98,0.95,0.88)


func _ready():
	#the board turns as long as the arrow is held
	holdKeys=true
		
	$chess_board.disableInfo()
	highlightCoordinates()

func highlightCoordinates():
	var board=$chess_board/chess_board
	var material=board.get_surface_override_material(0)
	#cartoon rendering disabled: original materials
	if !(material is ShaderMaterial) or material.shader!=ToonStyle.TOON_SHADER:
		return
	material=material.duplicate()
	material.set_shader_parameter("raised_height",COORDINATES_HEIGHT)
	material.set_shader_parameter("raised_color",COORDINATES_COLOR)
	board.set_surface_override_material(0,material)

#left / right turn the board, up / down do nothing
func onDirection(direction_,delta_):
	if direction_.x!=0:
		$chess_board.rotate_y( deg_to_rad( -direction_.x * ROTATE_SPEED) * delta_ )
