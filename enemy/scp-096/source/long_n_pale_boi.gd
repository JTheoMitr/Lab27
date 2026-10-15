extends CharacterBody3D

@export var move_speed: float = 3.0
@export var gravity: float = 20.0

@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
@onready var animation_player: AnimationPlayer = $SCP096/AnimationPlayer


func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player == null:
		return

	# Get the direction toward the player
	var direction := player.global_position - global_position

	# Ignore height
	direction.y = 0

	if direction.length() > 0.5:
		direction = direction.normalized()

		# Move toward player
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		# Face player
		look_at(
			Vector3(
				player.global_position.x,
				global_position.y,
				player.global_position.z
			),
			Vector3.UP
		)

		# Run
		if animation_player.current_animation != "C_096_DWlk_F - Forward":
			animation_player.play("C_096_DWlk_F - Forward")

	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
