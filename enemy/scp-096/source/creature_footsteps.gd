
extends Node3D

@export_group("Footstep Sounds")
@export var walking_sounds: Array[AudioStream] = []
@export var running_sounds: Array[AudioStream] = []

@export_group("Footstep Timing")
@export var walk_step_interval: float = 0.65
@export var run_step_interval: float = 0.28
@export var movement_threshold: float = 0.2

@export_group("Sound Variation")
@export var minimum_pitch: float = 0.92
@export var maximum_pitch: float = 1.05
@export var walking_volume_db: float = -8.0
@export var running_volume_db: float = 0.0

@export_group("Debug")
@export var debug_footsteps: bool = false

@onready var footstep_audio: AudioStreamPlayer3D = $FootstepAudio

var enemy: CharacterBody3D
var step_timer: float = 0.0
var previous_mode: int = 0
var last_step_index: int = -1


func _ready() -> void:
	enemy = get_parent() as CharacterBody3D

	if enemy == null:
		push_error("CreatureFootsteps must be a child of SCP-096.")
		set_physics_process(false)
		return

	if not enemy.has_method("get_footstep_mode"):
		push_error("SCP-096 is missing get_footstep_mode().")
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(enemy):
		return

	var mode: int = enemy.get_footstep_mode()

	var movement: Vector3 = enemy.get_real_velocity()
	movement.y = 0.0

	var horizontal_speed: float = movement.length()

	# Reset footstep timing when changing movement modes.
	if mode != previous_mode:
		step_timer = 0.0
		previous_mode = mode

	# No footsteps when idle, stunned, attacking, or stationary.
	if mode == 0 or not enemy.is_on_floor():
		step_timer = 0.0
		return

	if horizontal_speed < movement_threshold:
		step_timer = 0.0
		return

	var step_interval: float = walk_step_interval

	if mode == 2:
		step_interval = run_step_interval

	step_timer += delta

	if step_timer >= step_interval:
		step_timer -= step_interval
		play_footstep(mode)


func play_footstep(mode: int) -> void:
	var sounds: Array[AudioStream] = walking_sounds

	if mode == 2 and not running_sounds.is_empty():
		sounds = running_sounds

	if sounds.is_empty():
		return

	var index: int = randi_range(0, sounds.size() - 1)

	# Avoid identical consecutive sounds when possible.
	if sounds.size() > 1:
		while index == last_step_index:
			index = randi_range(0, sounds.size() - 1)

	last_step_index = index

	footstep_audio.stream = sounds[index]
	footstep_audio.pitch_scale = randf_range(
		minimum_pitch,
		maximum_pitch
	)

	if mode == 2:
		footstep_audio.volume_db = running_volume_db
	else:
		footstep_audio.volume_db = walking_volume_db

	footstep_audio.play()

	if debug_footsteps:
		print(
			"SCP FOOTSTEP | Mode: ", mode,
			" | Sound: ", index,
			" | Speed: ", enemy.get_real_velocity().length()
		)
