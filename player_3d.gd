extends CharacterBody3D

@export var move_speed: float = 15.0
@export var turn_speed: float = 2.5
@export var jump_velocity: float = 123.0
@export var gravity: float = 20.0

var action_animation_playing: bool = false

@onready var animation_player: AnimationPlayer = $arms_rig/AnimationPlayer

func _ready() -> void:
	pass
func _physics_process(delta: float) -> void:
	
	# Check player's birthday, if true, they get a gift (hat)

	# -------------------------
	# TURN
	# -------------------------

	var turn_input := Input.get_axis(
		"turn_left",
		"turn_right"
	)

	rotate_y(-turn_input * turn_speed * delta)


	# -------------------------
	# GRAVITY
	# -------------------------

	if not is_on_floor():
		velocity.y -= gravity * delta


	# -------------------------
	# JUMP
	# -------------------------

	if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = jump_velocity
		play_action_animation("push_L")

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


	if direction.length() > 0:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		#animation_player.play("RobotArmature|Robot_Running")

	else:
		velocity.x = 0
		velocity.z = 0
		#animation_player.play("RobotArmature|Robot_Idle")


	move_and_slide()
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
