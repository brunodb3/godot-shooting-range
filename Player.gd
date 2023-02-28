extends KinematicBody

export var speed := 7.0
export var jump_strength := 20.0
export var gravity := 50.0
export var mouse_sensitivity := 0.1
export var max_pivot_rotation := 40

var _velocity := Vector3.ZERO
var _snap_vector := Vector3.DOWN

onready var _arm_pivot = $ArmPivot
onready var _camera_pivot = $CameraPivot
onready var _raycast = $CameraPivot/Camera/RayCast

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))

		var rotation_x = deg2rad(-event.relative.y * mouse_sensitivity)

		_arm_pivot.rotate_x(rotation_x)
		_camera_pivot.rotate_x(rotation_x)

		_arm_pivot.rotation.x = clamp(_arm_pivot.rotation.x, deg2rad(-max_pivot_rotation), deg2rad(max_pivot_rotation))
		_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, deg2rad(-max_pivot_rotation), deg2rad(max_pivot_rotation))

func _input_move(delta: float) -> void:
	var move_direction := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		move_direction -= transform.basis.z
	elif Input.is_action_pressed("move_backward"):
		move_direction += transform.basis.z

	if Input.is_action_pressed("move_left"):
		move_direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		move_direction += transform.basis.x

	_velocity.x = move_direction.x * speed
	_velocity.z = move_direction.z * speed
	_velocity.y -= gravity * delta

	var just_landed := is_on_floor() and _snap_vector == Vector3.ZERO
	var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump")

	if is_jumping:
		_velocity.y = jump_strength
		_snap_vector = Vector3.ZERO
	elif just_landed:
		_snap_vector = Vector3.DOWN

	_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP, true)

func _input_shoot(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		var bullet = preload("res://Bullet.tscn").instance()

		get_parent().add_child(bullet)

		bullet.global_transform.origin = $ArmPivot/Weapon.global_transform.origin

		_raycast.force_raycast_update()

		if _raycast.is_colliding():
			var target = _raycast.get_collider().get_parent()
			target.queue_free()

func _physics_process(delta: float) -> void:
	_input_move(delta)
	_input_shoot(delta)
