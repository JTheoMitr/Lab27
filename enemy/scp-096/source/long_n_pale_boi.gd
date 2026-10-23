
extends CharacterBody3D

enum State {
	PASSIVE,
	INVESTIGATING,
	CHASING,
	SEARCHING,
	STUNNED,
	ATTACKING
}

# -------------------------
# MOVEMENT
# -------------------------

@export_group("Movement")
@export var walk_speed: float = 1.1
@export var investigate_speed: float = 2.0
@export var chase_speed: float = 5.5
@export var gravity: float = 20.0
@export var patrol_points: Array[Node3D] = []


@export var patrol_pause_duration: float = 5.0

var patrol_direction: int = 1
var patrol_waiting: bool = false
var patrol_wait_timer: float = 0.0


# -------------------------
# NAVIGATION
# -------------------------

@export_group("Navigation")
@export var navigation_height_offset: float = 0.0
@export var patrol_arrival_distance: float = 1.25
@export var target_update_distance: float = 0.5
@export var stuck_timeout: float = 3.0
@export var debug_navigation: bool = false



# -------------------------
# DETECTION
# -------------------------

@export_group("Long Vision")
@export var long_vision_range: float = 18.0
@export var long_vision_angle: float = 120.0
@export var long_detection_time: float = 2.5

@export_group("Short Vision")
@export var short_vision_range: float = 6.0
@export var short_vision_angle: float = 140.0

@export_group("Proximity")
@export var attack_proximity: float = 1.5

@export_group("Rage")
@export var rage_gain_rate: float = 12.0
@export var rage_decay_rate: float = 5.0

@export_group("Detection")
@export var eye_height: float = 1.5
@export_flags_3d_physics var sight_mask: int = 3


@export var debug_detection: bool = true

var long_sight_timer: float = 0.0


# -------------------------
# BEHAVIOR
# -------------------------

@export_group("Behavior")
@export var chase_rage: float = 75.0
@export var search_duration: float = 6.0
@export var stun_duration: float = 3.0
@export var attack_distance: float = 1.3

# -------------------------
# NODE REFERENCES
# -------------------------

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $LNPB2/AnimationPlayer

# -------------------------
# CREATURE SFX
# -------------------------

@onready var found_you: AudioStreamPlayer3D = $FoundYou
@onready var rushing: AudioStreamPlayer3D = $Rushing

# -------------------------
# VARIABLES
# -------------------------

var player: CharacterBody3D

var state: State = State.PASSIVE
var rage: float = 0.0
var state_timer: float = 0.0
var lost_sight_timer: float = 0.0

var navigation_ready: bool = false

var patrol_index: int = 0
var current_patrol_point: Node3D
var last_known_position: Vector3 = Vector3.ZERO

var stuck_timer: float = 0.0
var last_progress_position: Vector3 = Vector3.ZERO
var stuck_reported: bool = false


# -------------------------
# READY
# -------------------------

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	
	if is_instance_valid(player):
		print("SCP-096 FOUND PLAYER: ", player.name)
	else:
		push_warning("SCP-096 cannot find the player! Check the player group.")

	
	navigation_agent.path_height_offset = navigation_height_offset
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 0.75


	call_deferred("_start_navigation")


func _start_navigation() -> void:
	await get_tree().physics_frame

	navigation_ready = true
	last_progress_position = global_position

	enter_state(State.PASSIVE)

	debug_player_collision()
# -------------------------
# PHYSICS PROCESS
# -------------------------

func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if not navigation_ready or not is_instance_valid(player):
		stop_moving()
		move_and_slide()
		return

	state_timer += delta

	# -------------------------
	# PLAYER DETECTION
	# -------------------------

	
	var detection_level: int = get_detection_level()
	var sees_player: bool = detection_level > 0

	update_detection(delta, detection_level)

	if debug_detection and Engine.get_physics_frames() % 60 == 0:
		print(
			"DETECTION | Level: ", detection_level,
			" | Distance: ", snappedf(horizontal_distance_to_player(), 0.1),
			" | Rage: ", snappedf(rage, 0.1),
			" | Sight timer: ", snappedf(long_sight_timer, 0.1),
			" | State: ", State.keys()[state]
		)

	# -------------------------
	# STATE BEHAVIOR
	# -------------------------

	match state:





		State.PASSIVE:
			if patrol_waiting:
				patrol_wait_timer -= delta

				if patrol_wait_timer <= 0.0:
					patrol_waiting = false
					patrol_wait_timer = 0.0

					print("PATROL RESUMING toward index: ", patrol_index)
					choose_patrol_point()

			elif reached_patrol_point():
				print("ACTUALLY ARRIVED at: ", current_patrol_point.name)
				arrive_at_patrol_point()

			elif navigation_agent.is_navigation_finished():
				if is_instance_valid(current_patrol_point):
					var final_position: Vector3 = navigation_agent.get_final_position()

					var distance_to_final: Vector3 = final_position - global_position
					distance_to_final.y = 0.0

					var final_to_marker: Vector3 = current_patrol_point.global_position - final_position
					final_to_marker.y = 0.0

					if distance_to_final.length() <= 0.85 and final_to_marker.length() <= 2.0:
						print("ARRIVED AT NAVIGATION END: ", current_patrol_point.name)
						arrive_at_patrol_point()

					elif debug_navigation and Engine.get_physics_frames() % 60 == 0:
						print(
							"PATROL PATH ENDED | Marker: ", current_patrol_point.name,
							" | Distance to endpoint: ", distance_to_final.length(),
							" | Endpoint to marker: ", final_to_marker.length()
						)

		State.INVESTIGATING:
			if sees_player:
				set_target(player.global_position)
				
			elif navigation_agent.is_navigation_finished():
				enter_state(State.SEARCHING)

		State.CHASING:
			if sees_player:
				lost_sight_timer = 0.0
				#rushing.play()
				set_target(player.global_position)

				if horizontal_distance_to_player() <= attack_distance:
					enter_state(State.ATTACKING)
			else:
				lost_sight_timer += delta

				if lost_sight_timer >= 2.0:
					enter_state(State.SEARCHING)

		State.SEARCHING:
			if state_timer >= search_duration:
				enter_state(State.PASSIVE)

		State.STUNNED:
			if state_timer >= stun_duration:
				enter_state(State.SEARCHING)

		State.ATTACKING:
			pass

	# -------------------------
	# SELECT MOVEMENT SPEED
	# -------------------------

	var current_speed: float = 0.0


	match state:
		State.PASSIVE:
			current_speed = 0.0 if patrol_waiting else walk_speed


		State.INVESTIGATING:
			current_speed = investigate_speed

		State.CHASING:
			current_speed = chase_speed

		State.SEARCHING:
			current_speed = investigate_speed

	# -------------------------
	# NAVIGATION AND MOVEMENT
	# -------------------------

	follow_navigation(current_speed)
	move_and_slide()

	if current_speed > 0.0:
		check_stuck(delta)
	else:
		reset_stuck_tracking()


# -------------------------
# AWARENESS / RAGE
# -------------------------


func update_detection(delta: float, detection_level: int) -> void:
	if state == State.STUNNED or state == State.ATTACKING:
		return

	if detection_level > 0:
		last_known_position = player.global_position
		rage = minf(rage + rage_gain_rate * delta, 100.0)
	else:
		rage = maxf(rage - rage_decay_rate * delta, 0.0)

	# Immediate attack.
	if detection_level == 3:
		if debug_detection:
			print("SCP-096 PROXIMITY ATTACK!")

		enter_state(State.ATTACKING)
		return

	# Immediate chase from short vision.
	if detection_level == 2:
		long_sight_timer = long_detection_time

		if state != State.CHASING:
			if debug_detection:
				print("SCP-096 SHORT VISION — CHASING!")

			enter_state(State.CHASING)
			rushing.play()

		return

	# Delayed chase from long vision.
	if detection_level == 1:
		long_sight_timer += delta

		if state == State.PASSIVE or state == State.SEARCHING:
			if debug_detection:
				print("SCP-096 LONG VISION — INVESTIGATING!")

			enter_state(State.INVESTIGATING)
			found_you.play()

		var required_time: float = long_detection_time

		# Higher rage shortens the reaction time.
		if rage >= chase_rage:
			required_time *= 0.5

		if long_sight_timer >= required_time:
			if state != State.CHASING:
				if debug_detection:
					print("SCP-096 DETECTION TIMER COMPLETE — CHASING!")

				enter_state(State.CHASING)

		return

	# Player is no longer visible.
	# Awareness fades gradually instead of instantly resetting.
	long_sight_timer = maxf(long_sight_timer - delta, 0.0)

# -------------------------
# PLAYER VISION
# -------------------------


func player_in_vision(vision_distance: float, vision_angle: float) -> bool:
	if not is_instance_valid(player):
		return false

	var eye: Vector3 = global_position + Vector3.UP * eye_height
	var target: Vector3 = player.global_position + Vector3.UP * 1.0

	var offset: Vector3 = target - eye

	if offset.length() > vision_distance:
		return false

	# SCP-096 faces local -Z.
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var direction: Vector3 = offset
	direction.y = 0.0

	if direction.length_squared() > 0.001:
		var angle: float = rad_to_deg(
			forward.angle_to(direction.normalized())
		)

		if angle > vision_angle * 0.5:
			return false

	return has_line_of_sight()





func has_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false

	var eye: Vector3 = global_position + Vector3.UP * eye_height
	var target: Vector3 = player.global_position

	var player_shape: CollisionShape3D = null

	for child in player.get_children():
		if child is CollisionShape3D and not child.disabled:
			player_shape = child
			break

	if player_shape != null:
		target = player_shape.global_position

	var query := PhysicsRayQueryParameters3D.create(
		eye,
		target,
		sight_mask
	)

	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if debug_detection and Engine.get_physics_frames() % 60 == 0:
		print(
			"VISION | Eye: ", eye,
			" | Target: ", target,
			" | Hit: ", result.get("collider", "NOTHING"),
			" | Shape found: ", player_shape != null
		)

	if result.is_empty():
		return false

	return result["collider"] == player

func get_detection_level() -> int:
	if not is_instance_valid(player):
		return 0

	var distance: float = horizontal_distance_to_player()

	if distance <= attack_proximity and has_line_of_sight():
		return 3

	if player_in_vision(short_vision_range, short_vision_angle):
		return 2

	if player_in_vision(long_vision_range, long_vision_angle):
		return 1

	return 0




# -------------------------
# STATE CHANGES
# -------------------------

func enter_state(new_state: State) -> void:

	state = new_state
	state_timer = 0.0
	
	patrol_waiting = false
	patrol_wait_timer = 0.0

	reset_stuck_tracking()

	match state:

		State.PASSIVE:
			rage = 0.0
			choose_patrol_point()

		State.INVESTIGATING:
			set_target(last_known_position)
			play_animation("Walk")

		State.CHASING:
			lost_sight_timer = 0.0
			set_target(player.global_position)
			play_animation("Running")

		State.SEARCHING:
			set_target(last_known_position)
			play_animation("Walk")

		State.STUNNED:
			stop_moving()
			play_animation("Swing")

		State.ATTACKING:
			stop_moving()
			play_animation("Attack")


# -------------------------
# PATROL SYSTEM
# -------------------------

#func choose_patrol_point() -> void:
#
	#if patrol_points.is_empty():
		#current_patrol_point = null
		#stop_moving()
		#play_animation("Idle Near")
		#return
#
	#var point: Node3D = patrol_points[patrol_index]
#
	#patrol_index = (patrol_index + 1) % patrol_points.size()
#
	#if not is_instance_valid(point):
		#push_warning("Invalid patrol point!")
		#current_patrol_point = null
		#return
#
	#current_patrol_point = point
#
	## Set the patrol destination directly.
	#navigation_agent.target_position = point.global_position
#
	#reset_stuck_tracking()
	#play_animation("Walk Near")
#
	#if debug_navigation:
		#print("SCP-096 heading toward: ", point.name)




func reached_patrol_point() -> bool:
	return patrol_distance() <= patrol_arrival_distance

# -------------------------
# SET NAVIGATION TARGET
# -------------------------

func set_target(target: Vector3) -> void:

	if navigation_agent.target_position.distance_squared_to(target) > (
		target_update_distance * target_update_distance
	):
		navigation_agent.target_position = target


# -------------------------
# FOLLOW NAVIGATION
# -------------------------

func follow_navigation(speed: float) -> void:

	if speed <= 0.0:
		stop_moving()
		return

	if navigation_agent.is_navigation_finished():
		stop_moving()

		if state == State.PASSIVE:
			play_animation("Idle Near")
		elif state == State.SEARCHING:
			play_animation("Idle")

		return

	var next_point: Vector3 = navigation_agent.get_next_path_position()

	var direction: Vector3 = next_point - global_position
	direction.y = 0.0

	if direction.length_squared() < 0.0001:
		stop_moving()
		return

	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Face movement direction.
	var look_target: Vector3 = global_position + direction

	if global_position.distance_squared_to(look_target) > 0.0001:
		look_at(look_target, Vector3.UP)

	# Match movement animation to state.
	match state:

		State.PASSIVE:
			play_animation("Walk Near")

		State.INVESTIGATING, State.SEARCHING:
			play_animation("Walk")

		State.CHASING:
			play_animation("Running")

	if debug_navigation and Engine.get_physics_frames() % 60 == 0:
		print(
			"SCP State: ", State.keys()[state],
			" | Position: ", global_position,
			" | Next: ", next_point,
			" | Target: ", navigation_agent.target_position,
			" | Reachable: ", navigation_agent.is_target_reachable(),
			" | Final: ", navigation_agent.get_final_position()
		)


# -------------------------
# STUCK DETECTION
# -------------------------

func check_stuck(delta: float) -> void:

	if navigation_agent.is_navigation_finished():
		reset_stuck_tracking()
		return

	var movement: Vector3 = global_position - last_progress_position
	movement.y = 0.0

	if movement.length() >= 0.3:
		reset_stuck_tracking()
		return

	stuck_timer += delta

	if stuck_timer >= stuck_timeout and not stuck_reported:
		stuck_reported = true

		if debug_navigation:
			print(
				"SCP-096 stalled while heading toward: ",
				navigation_agent.target_position
			)

		# Do not automatically skip patrol points.
		# We want SCP-096 to visit every marker.


func reset_stuck_tracking() -> void:
	stuck_timer = 0.0
	last_progress_position = global_position
	stuck_reported = false


# -------------------------
# MOVEMENT HELPERS
# -------------------------

func stop_moving() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func horizontal_distance_to_player() -> float:

	if not is_instance_valid(player):
		return INF

	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0

	return offset.length()


# -------------------------
# ANIMATIONS
# -------------------------

func play_animation(anim_name: String) -> void:

	if not animation_player.has_animation(anim_name):
		push_warning("Missing animation: " + anim_name)
		return

	if animation_player.current_animation != anim_name or not animation_player.is_playing():
		animation_player.play(anim_name)


# -------------------------
# SOUND DETECTION
# -------------------------

func hear_noise(noise_position: Vector3, rage_increase: float = 15.0) -> void:

	if state == State.STUNNED or state == State.ATTACKING:
		return

	rage = minf(rage + rage_increase, 100.0)
	last_known_position = noise_position

	if rage >= chase_rage:
		enter_state(State.CHASING)
	else:
		enter_state(State.INVESTIGATING)


# -------------------------
# STUN
# -------------------------

func stun() -> void:

	if state == State.STUNNED:
		return

	rage = minf(rage + 25.0, 100.0)
	enter_state(State.STUNNED)



func choose_patrol_point() -> void:
	if patrol_points.is_empty():
		current_patrol_point = null
		stop_moving()
		play_animation("Idle Near")
		return

	patrol_index = clampi(patrol_index, 0, patrol_points.size() - 1)

	var point: Node3D = patrol_points[patrol_index]

	if not is_instance_valid(point):
		push_warning("Invalid patrol point!")
		return

	current_patrol_point = point
	navigation_agent.target_position = point.global_position

	reset_stuck_tracking()
	play_animation("Walk Near")

	if debug_navigation:
		print("Heading to patrol point: ", point.name)




func arrive_at_patrol_point() -> void:
	if patrol_points.is_empty():
		return

	stop_moving()

	var last_index: int = patrol_points.size() - 1
	var at_endpoint: bool = patrol_index == 0 or patrol_index == last_index

	if at_endpoint:
		patrol_waiting = true
		patrol_wait_timer = patrol_pause_duration

		play_animation("Idle Near")

		if patrol_index == last_index:
			patrol_direction = -1
		else:
			patrol_direction = 1

	else:
		patrol_waiting = false

	patrol_index += patrol_direction

	if debug_navigation:
		print(
			"ARRIVED | Next index: ", patrol_index,
			" | Waiting: ", patrol_waiting,
			" | Timer: ", patrol_wait_timer
		)

	if not patrol_waiting:
		choose_patrol_point()


func patrol_distance() -> float:
	if not is_instance_valid(current_patrol_point):
		return INF

	var difference: Vector3 = current_patrol_point.global_position - global_position
	difference.y = 0.0

	return difference.length()


func debug_player_collision() -> void:
	if not is_instance_valid(player):
		print("No valid player!")
		return

	print("PLAYER ROOT: ", player.global_position)
	print("PLAYER LAYER: ", player.collision_layer)

	for child in player.get_children():
		if child is CollisionShape3D:
			print("COLLISION SHAPE: ", child.name)
			print("WORLD POSITION: ", child.global_position)
			print("DISABLED: ", child.disabled)
			print("SHAPE RESOURCE: ", child.shape)

			if child.shape is CapsuleShape3D:
				print("CAPSULE HEIGHT: ", child.shape.height)
				print("CAPSULE RADIUS: ", child.shape.radius)
