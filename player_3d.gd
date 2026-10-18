extends CharacterBody3D

@export var walk_speed: float = 2.0
@export var sprint_speed: float = 4.5
@export var turn_speed: float = 2.5
@export var jump_velocity: float = 5.0
@export var gravity: float = 20.0

var action_animation_playing: bool = false

@export var mouse_sensitivity: float = 0.0045

@onready var camera: Camera3D = $Camera3D

@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

@onready var animation_player: AnimationPlayer = $Camera3D/arms_rig/AnimationPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
func _physics_process(delta: float) -> void:
	
	# Check player's birthday, if true, they get a gift (hat)

	# -------------------------
	# TURN
	# -------------------------

	#var turn_input := Input.get_axis(
		#"turn_left",
		#"turn_right"
	#)
#
	#rotate_y(-turn_input * turn_speed * delta)


	# -------------------------
	# GRAVITY
	# -------------------------

	if not is_on_floor():
		velocity.y -= gravity * delta


	# -------------------------
	# PUSH
	# -------------------------

	if Input.is_action_just_pressed("interact") and is_on_floor():
		#velocity.y = jump_velocity
		play_action_animation("push_L")
		
	# -------------------------
	# JUMP
	# -------------------------
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
	# -------------------------
	# MOVEMENT
	# -------------------------

	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := (
		transform.basis * Vector3(
			input_direction.x,
			0,
			input_direction.y
		)
	)

	direction.y = 0
	direction = direction.normalized()


	var current_speed: float = walk_speed

	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	if direction.length() > 0:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	if Input.is_action_pressed("move_forward"):
		print(
			"Requested speed: ", current_speed,
			" | Actual speed: ", get_real_velocity().length(),
			" | On floor: ", is_on_floor(),
			" | On wall: ", is_on_wall()
		)
	update_animation()
	

func play_action_animation(animation_name: String) -> void:
	action_animation_playing = true
	
	var animation = animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_NONE
	
	animation_player.play(animation_name)
	
	await animation_player.animation_finished
	
	action_animation_playing = false
	
func update_animation() -> void:
	if action_animation_playing:
		return

	#if velocity.x != 0 or velocity.z != 0:
		#play_looping_animation("CharacterArmature|Run")
	#else:
		#play_looping_animation("CharacterArmature|Idle")
		#

func play_looping_animation(animation_name: String) -> void:
	var animation = animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR

	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# Horizontal: turn the entire player
			rotate_y(-event.screen_relative.x * mouse_sensitivity)

			# Vertical: tilt only the camera
			camera.rotate_x(-event.screen_relative.y * mouse_sensitivity)

			# Prevent looking too far up or down
			camera.rotation.x = clamp(
				camera.rotation.x,
				deg_to_rad(-85.0),
				deg_to_rad(85.0)
			)

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event.is_action_pressed("interact"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			try_interact()
			
			
func try_interact() -> void:
	if not interaction_ray.is_colliding():
		return

	var hit = interaction_ray.get_collider()

	if hit == null:
		return

	# The ray hits the door's Area3D.
	# Its parent has our door interaction script.
	var interactable = hit.get_parent()

	if interactable.has_method("interact"):
		interactable.interact()
