extends RigidBody

export (NodePath) var camera_path : NodePath

export var turn_weight : int = 20
export var rotation_weight: int = 7
export var move_speed : int = 120
export var min_strong_len : float = 0.2
export var max_speed : int = 10
export var jump_force : int = 25
export var on_gravity_multi_jump : int = 7
export var on_air_divider : float = 0.6

var move_dir : Vector3 = Vector3.ZERO
var last_strong_direction : Vector3 = Vector3.FORWARD
var is_jumping : bool = false
var raw_input : Vector2 = Vector2.ZERO
var fwd_bwd : float = 0
var lft_rgt : float = 0
var cam_basis_x : Vector3 = Vector3.ZERO
var cam_basis_z : Vector3 = Vector3.ZERO
var on_orbit : bool = false
var on_floor : bool = false
var gravity_center : Vector3 = Vector3.ZERO

onready var original: Transform = transform.basis
onready var original_y: Vector3 = transform.basis.y
onready var original_origin:Vector3 = transform.origin
onready var camera : Spatial = get_node(camera_path)

func set_on_orbit(is_on_orbit:bool=!on_orbit, gravity_origin: Vector3 = Vector3.ZERO) -> void:
	on_orbit = is_on_orbit
	gravity_center = gravity_origin
	
func set_off_orbit(is_on_orbit:bool = !on_orbit, gravity_origin:Vector3 = Vector3.UP) -> void:
	on_orbit = is_on_orbit
	gravity_center = gravity_origin
	transform.basis.y = lerp(transform.basis.y, gravity_origin, rotation_weight*get_physics_process_delta_time())
	
func set_original_y() -> void:
	transform.basis.y = lerp(transform.basis.y, original_y, rotation_weight*get_physics_process_delta_time())
	
func align_with_gravity() -> void:
	var gravitate: Vector3 = (gravity_center - global_transform.origin).normalized()
	var left_axis = -gravitate.cross($Mesh.rotation)
	var rotation_basis := Basis(left_axis, -gravitate, $Mesh.rotation).orthonormalized()
	transform.basis = transform.basis.get_rotation_quat().slerp(rotation_basis, get_physics_process_delta_time()*rotation_weight)

func get_input_camera_oriented()->Vector3:
	fwd_bwd = Input.get_action_strength("move_bwd")-Input.get_action_strength("move_fwd")
	lft_rgt = Input.get_action_strength("move_rgt")-Input.get_action_strength("move_lft")
	raw_input = Vector2(lft_rgt, fwd_bwd)
	var input : Vector3 = Vector3.ZERO
	
	input.x = raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y/2)
	input.z = raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x/2)
	
	var final_input = cam_basis_z * input.z
	final_input += cam_basis_x * input.x
	
	final_input = transform.basis.xform(final_input)
	return final_input.normalized()

func is_on_floor(state: PhysicsDirectBodyState) -> bool:
	for contact in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(contact)
		if contact_normal.dot(Vector3.UP) > 0.5:
			return true
	return false

func jump() -> bool:
	apply_central_impulse(transform.basis.xform(Vector3.UP*(jump_force*1 if !on_orbit else jump_force* on_gravity_multi_jump)))
	return true
	
func controlability(state: PhysicsDirectBodyState)-> float:
	return 1 if on_floor else on_air_divider
	
func _physics_process(delta)-> void:
	if on_orbit:
		align_with_gravity()
	else:
		set_original_y()
	$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(move_dir.x, move_dir.z), delta*turn_weight) if !(move_dir.x == 0 and move_dir.z == 0) else $Mesh.rotation.y
	
func _process(delta):
	cam_basis_z = Vector3(camera.transform.basis.z.x,0, camera.transform.basis.z.z)
	cam_basis_x = Vector3(camera.transform.basis.x.x,0, camera.transform.basis.x.z)

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	on_floor = is_on_floor(state) or $Mesh/RayCast.is_colliding()
	move_dir = get_input_camera_oriented()
	last_strong_direction = move_dir.normalized() if move_dir.length() > min_strong_len else last_strong_direction
	add_central_force(move_dir*move_speed*controlability(state))
	is_jumping = jump() if on_floor and Input.is_action_pressed("jump") else false
	state.linear_velocity.x = clamp(state.linear_velocity.x, -max_speed, max_speed)
	state.linear_velocity.z = clamp(state.linear_velocity.z, -max_speed, max_speed)
