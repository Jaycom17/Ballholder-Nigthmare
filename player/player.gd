class_name Player
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4

var coyote_time := 0.15
var coyote_timer := 0.0

func _physics_process(delta: float) -> void:
	# Manejo de coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Aplicar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Saltar con coyote time
	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0

	# Movimiento horizontal
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
