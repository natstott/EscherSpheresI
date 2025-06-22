extends MeshInstance3D
var angular_speed = PI/5

func _process(delta):
	#var inv_model = global_transform.affine_inverse()
	#self.get_active_material(0).set_shader_parameter("inv_model_matrix", inv_model)
	rotate(Vector3(0, 1, 0), angular_speed*delta)
	pass
	


func _on_scale_slider_value_changed(value: float) -> void:
	self.get_active_material(0).set_shader_parameter("testscaler", value)
