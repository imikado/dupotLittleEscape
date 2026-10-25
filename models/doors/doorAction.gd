extends MeshInstance3D

const OPEN_ANGLE=deg_to_rad(85)

func open():
	rotate(Vector3(0,1,0),OPEN_ANGLE)
	
func close():
	rotate(Vector3(0,1,0),-OPEN_ANGLE)
