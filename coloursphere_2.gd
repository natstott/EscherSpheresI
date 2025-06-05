extends MeshInstance3D
func _ready():
	#var basis= Basis()
	transform.basis= transform.basis.rotated(Vector3.UP,PI/4)
	transform.basis=transform.basis.rotated(Vector3.RIGHT,PI/2)
	transform.basis= transform.basis.rotated(Vector3.UP,PI/8)
	print("sphere2:", transform.basis)
