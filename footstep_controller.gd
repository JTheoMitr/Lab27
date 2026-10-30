
extends Node

@export_group("References")
@export var player: CharacterBody3D

@onready var footstep_audio: AudioStreamPlayer = $FootstepAudio

@export_group("Footstep Sounds")
@export var footstep_sounds: Array[AudioStream] = []

@export_group("Timing")
@export var walk_step_interval: float = 0.52
@export var sprint_step_interval: float = 0.32
@export var movement_threshold: float = 0.2
@export var sprint_speed_threshold: float = 3.3

@export_group("Audio Variation")
@export var minimum_pitch: float = 0.95
@export var maximum_pitch: float = 1.05


@export_group("Stealth Noise")
@export var crouch_hearing_radius: float = 1.5
@export var walk_hearing_radius: float = 5.0
@export var sprint_hearing_radius: float = 10.0
@export var crouch_step_interval: float = 0.85
@export var debug_noise: bool = false


var step_timer: float = 0.0
var last_step_index: int = -1


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if footstep_sounds.is_empty():
		return

	var actual_velocity: Vector3 = player.get_real_velocity()
	actual_velocity.y = 0.0

	var horizontal_speed: float = actual_velocity.length()

	if not player.is_on_floor() or horizontal_speed < movement_threshold:
		step_timer = 0.0
		return

	
	var interval: float = walk_step_interval

	if player.is_crouching:
		interval = crouch_step_interval
	elif horizontal_speed >= sprint_speed_threshold:
		interval = sprint_step_interval


	step_timer += delta

	if step_timer >= interval:
		step_timer -= interval
		play_footstep()


func play_footstep() -> void:
	if footstep_sounds.is_empty():
		return

	var index: int = randi_range(0, footstep_sounds.size() - 1)

	if footstep_sounds.size() > 1:
		while index == last_step_index:
			index = randi_range(0, footstep_sounds.size() - 1)

	last_step_index = index

	footstep_audio.stream = footstep_sounds[index]
	footstep_audio.pitch_scale = randf_range(minimum_pitch, maximum_pitch)
	
	
	if player.is_crouching:
		footstep_audio.volume_db = -35.0
	else:
		footstep_audio.volume_db = -25.0

	
	footstep_audio.play()
	emit_footstep_noise()


func emit_footstep_noise() -> void:
	if not is_instance_valid(player):
		return

	var hearing_radius: float = walk_hearing_radius

	var movement: Vector3 = player.get_real_velocity()
	movement.y = 0.0

	if player.is_crouching:
		hearing_radius = crouch_hearing_radius
	elif movement.length() >= sprint_speed_threshold:
		hearing_radius = sprint_hearing_radius

	for creature in get_tree().get_nodes_in_group("creature"):
		if not creature is Node3D:
			continue

		if not creature.has_method("hear_footstep"):
			continue

		var distance: float = player.global_position.distance_to(
			creature.global_position
		)

		if distance <= hearing_radius:
			creature.hear_footstep(player.global_position)

			if debug_noise:
				print(
					"FOOTSTEP HEARD | Distance: ",
					snappedf(distance, 0.1),
					" | Radius: ",
					hearing_radius
				)
