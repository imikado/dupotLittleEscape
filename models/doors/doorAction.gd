extends MeshInstance3D

func open():
	rotate(Vector3(0,1,0),-85)
	
func close():
	rotate(Vector3(0,1,0),85)
