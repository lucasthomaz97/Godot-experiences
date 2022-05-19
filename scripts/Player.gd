extends KinematicBody

export var JUMP = 35
export var SPEED = 100
export var MOVE_MULTI = 2.5
export var GRAVITY = 0.98
export var GRAVITY_SPEED = 1.2
export var MAX_FALL_SPEED = 50
export var y_sens = 1.0
export var x_sens = 1.0

var move_vec = Vector3.ZERO
var y_velo = 0
onready var cam_basis_x := Vector3.ZERO
onready var cam_basis_z := Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func play_anim(anim):
	if $Anim.current_animation == anim:
		return
	$Anim.play(anim)

func _input(event):
	if event is InputEventMouseMotion:
		$Pivot.rotation_degrees.x -= event.relative.y * y_sens
		$Pivot.rotation_degrees.y -= event.relative.x * x_sens
		$Pivot.rotation_degrees.x = clamp($Pivot.rotation_degrees.x, -90, 90)
		
func _process(delta):
	cam_basis_z = Vector3($Pivot.transform.basis.z.x,0,$Pivot.transform.basis.z.z)
	cam_basis_x = Vector3($Pivot.transform.basis.x.x,0,$Pivot.transform.basis.x.z)

func _physics_process(delta):
	move_vec = ((Input.get_action_strength("move_bwd")-Input.get_action_strength("move_fwd"))*cam_basis_z)+((Input.get_action_strength("move_rgt")-Input.get_action_strength("move_lft"))*cam_basis_x)
	move_vec = move_vec.normalized()*MOVE_MULTI
	move_vec *= SPEED
	move_vec.y = y_velo
	$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(-move_vec.x, -move_vec.z), delta*20) if !(move_vec.x == 0 and move_vec.z == 0) else $Mesh.rotation.y
	move_and_slide(move_vec, Vector3.UP)
	var grounded = is_on_floor()
	var just_jumped = true if grounded and Input.is_action_just_pressed("jump") else false
	y_velo = y_velo-(GRAVITY*GRAVITY_SPEED) if !just_jumped else JUMP
	y_velo = -MAX_FALL_SPEED if y_velo < -MAX_FALL_SPEED else y_velo
	
