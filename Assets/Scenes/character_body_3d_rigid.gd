extends RigidBody3D

@export var ROTATION_SPEED = 100
@export var MOVE_SPEED = 100
@export var JUMP_STRENGTH = 100



var move_direction = Vector3.ZERO
var last_strong_direction = Vector3.ZERO
var local_gravity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	local_gravity = state.total_gravity.normalized()
	
	if move_direction.length() > 0.2:
		last_strong_direction = move_direction.normalized()
			
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	move_direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	
	_orient_character_to_direction(move_direction, state.step)
	if is_on_floor(state) and Input.get_action_strength("Jump") > 0.5:
		apply_central_impulse(-local_gravity * JUMP_STRENGTH)

	apply_central_force(move_direction*MOVE_SPEED)
		
	
	

func _orient_character_to_direction(direction: Vector3, delta: float):
	var left_axis = local_gravity.cross(direction)
	var rotation_basis = Basis(left_axis, -local_gravity, direction).orthonormalized()
	#transform.basis = transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * ROTATION_SPEED)
		

func is_on_floor(state: PhysicsDirectBodyState3D):
	for contact in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(contact)
		if contact_normal.dot(-local_gravity) > 0.5:
			return true
	return false
