extends CharacterBody3D

@export_group("Camera")
@export_range(0, 1) var mouse_sensitivity := 0.005

@export_group("Movement")
@export var move_speed := 5.0
@export var jump_speed := 4.5
@export var orientation_speed := 6.0

@export_group("Rocket")
@export var rocket_speed := 13.0
@export_range(0, 1) var current_fuel := 1.0
@export var fuel_reserve := 15.0
@export var fuel_burning_speed := 0.7
@export var fuel_refill_speed := 0.4

@onready var camera_3d: Camera3D = %Camera3D
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var fuel_reserve_bar: TextureProgressBar = %FulReserveBar

var _mouse_movement := Vector2.ZERO
var normal_velocity := Vector3.ZERO
var planar_velocity := Vector3.ZERO
var pitch_angle := 0.0

const MAX_PITCH := deg_to_rad(89.0)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	fuel_reserve_bar.max_value = fuel_reserve
	fuel_reserve_bar.value = fuel_reserve
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Left click Mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("Escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_mouse_movement = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	var gravity = get_gravity()
	up_direction = -gravity.normalized()
	
	# Handle mouse movement
	var yaw = Basis(up_direction, -_mouse_movement.x)
	transform.basis = (yaw * transform.basis).orthonormalized()
	
	pitch_angle += -_mouse_movement.y
	pitch_angle = clamp(pitch_angle, -MAX_PITCH, MAX_PITCH)
	camera_3d.transform.basis = Basis.IDENTITY
	camera_3d.rotate_object_local(Vector3.RIGHT, pitch_angle)

	_mouse_movement = Vector2.ZERO
	
	orient_character(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity += gravity * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity += up_direction * jump_speed
	var rocket_move := Input.get_axis("Down", "Up")
	# Handle planar movement
	var input_mov := Input.get_vector("Left", "Right", "Forward", "Backward")
	var movement := (transform.basis * Vector3(input_mov.x, 0, input_mov.y)).normalized()
	var normal_movement = up_direction *  up_direction.dot(movement)
	var planar_movement = movement - normal_movement
	
	normal_velocity =  up_direction * up_direction.dot(velocity)
	if rocket_move and current_fuel > 0:
		current_fuel = max(0, current_fuel - fuel_burning_speed * delta)
		normal_velocity += up_direction * rocket_speed * rocket_move * delta
	elif not rocket_move and current_fuel < 1 and fuel_reserve > 0:
		current_fuel = min(1, current_fuel + fuel_refill_speed * delta)
		fuel_reserve = max(0, fuel_reserve - fuel_refill_speed * delta)
	
	fuel_bar.value = current_fuel
	fuel_reserve_bar.value = fuel_reserve

	if planar_movement:
		planar_velocity = planar_movement * move_speed 
	else:
		planar_velocity = planar_velocity.move_toward(Vector3.ZERO, move_speed)
	
	velocity = planar_velocity + normal_velocity
	move_and_slide()


func orient_character(delta: float):
	# Orient character to up direction(delta)
	var rotation_axis = transform.basis.y.cross(up_direction)
	var rotation_angle = transform.basis.y.angle_to(up_direction)
	
	if rotation_axis.length() > 0.1:
		var target_basis = Basis(rotation_axis.normalized(), rotation_angle) * transform.basis
		transform.basis = transform.basis.slerp(target_basis, orientation_speed * delta).orthonormalized()
	elif rotation_axis.length() > 0:
		var target_basis = Basis(rotation_axis.normalized(), rotation_angle) * transform.basis
		transform.basis = target_basis
