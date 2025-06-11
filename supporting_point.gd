extends Node3D
var rotationspeed=2*PI
var angles
var mouseisdown
var lastangle =Vector3(0.0,0.0,0.0)
var currentangle=Vector3(0.0,0.0,0.0)
var startclick

func _physics_process(_delta: float) -> void:
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT ):
		var screen=get_viewport().get_visible_rect().size
		if !mouseisdown:
			mouseisdown=true
			startclick=get_viewport().get_mouse_position()/screen-Vector2(0.5,0.5)
		var mouse =get_viewport().get_mouse_position()/screen-Vector2(0.5,0.5)-startclick
		currentangle=Vector3(mouse.y,mouse.x,0)*rotationspeed
		self.rotation = lastangle+currentangle
	elif mouseisdown:
		lastangle+= currentangle
		mouseisdown=false
		
	
