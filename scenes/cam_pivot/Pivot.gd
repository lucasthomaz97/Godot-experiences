extends SpringArm

export var y_sens : float = 1.0
export var x_sens : float = 1.0
export var clamp_amount_min : int = -45
export var clamp_amount_max : int = 60

func _input(event) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.x -= event.relative.y * y_sens
		rotation_degrees.y -= event.relative.x * x_sens
	
	rotation_degrees.x = clamp(rotation_degrees.x, clamp_amount_min, clamp_amount_max)
