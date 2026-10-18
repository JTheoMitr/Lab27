
extends CharacterBody3D

@export var move_speed: float = 3.0
@export var gravity: float = 20.0
@export var stopping_distance: float = 1.0
@export var repath_distance: float = 0.5

@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
@onready var animation_player: AnimationPlayer = $SCP096/AnimationPlayer
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

const WALK_ANIMATION: String = "C_096_DWlk_F - Forward"

var navigation_ready: bool = false
var last_target_position: Vector3 = Vector3.INF


func _ready() -> void:
	# Navigation maps need a physics frame to synchronize.
	call_deferred("_initialize_navigation")


func _initialize_navigation() -> void:
	await get_tree().physics_frame

	navigation_ready = true

	if player == null:
		push_warning("SCP-096: Player not found in 'player' group!")
		return

	last_target_position = player.global_position
	navigation_agent.target_position = last_target_position


func _physics_process(delta: float) -> void:

	# -------------------------
	# GRAVITY
	# -------------------------
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# -------------------------
	# CHECK PLAYER / NAVIGATION
	# -------------------------
	if player == null or not navigation_ready:
		stop_horizontal_movement()
		move_and_slide()
		return

	# Stop when close enough to the player.
	var player_offset: Vector3 = player.global_position - global_position
	player_offset.y = 0.0

	if player_offset.length_squared() <= stopping_distance * stopping_distance:
		stop_horizontal_movement()
		move_and_slide()
		return

	# Update the navigation destination when the player
	# has moved enough to justify recalculating the path.
	if player.global_position.distance_squared_to(last_target_position) > repath_distance * repath_distance:
		last_target_position = player.global_position
		navigation_agent.target_position = last_target_position

	# -------------------------
	# NAVIGATION
	# -------------------------
	var direction: Vector3 = Vector3.ZERO

	if not navigation_agent.is_navigation_finished():
		var next_position: Vector3 = navigation_agent.get_next_path_position()

		direction = next_position - global_position
		direction.y = 0.0

		# Ignore extremely small directions.
		if direction.length_squared() > 0.0001:
			direction = direction.normalized()
		else:
			direction = Vector3.ZERO

	# -------------------------
	# MOVEMENT AND ROTATION
	# -------------------------
	if direction != Vector3.ZERO:

		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		# look_at() needs a valid world-space target.
		var look_target: Vector3 = global_position + direction

		if global_position.distance_squared_to(look_target) > 0.0001:
			look_at(look_target, Vector3.UP)

		# Play the original working walking animation.
		if animation_player.has_animation(WALK_ANIMATION):
			if animation_player.current_animation != WALK_ANIMATION or not animation_player.is_playing():
				animation_player.play(WALK_ANIMATION)

	else:
		stop_horizontal_movement()

	move_and_slide()


func stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
