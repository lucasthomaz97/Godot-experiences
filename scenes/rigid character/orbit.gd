extends Area

func _on_Area_body_entered(body):
	if body.has_method("set_on_orbit"):
		body.set_on_orbit(true, global_transform.origin)

func _on_Area_body_exited(body):
	if body.has_method("set_off_orbit"):
		body.set_off_orbit(false,Vector3.UP)
