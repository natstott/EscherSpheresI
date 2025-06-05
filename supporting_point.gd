extends Node3D
var rotationspeed=2*PI
var angles

func _physics_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT ):
		var screen=get_viewport().get_visible_rect().size
		var mouse =get_viewport().get_mouse_position()/screen-Vector2(0.5,0.5)
		angles=Vector3(mouse.y,mouse.x,0)*rotationspeed
		self.rotation = angles
