
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

	if horizontal_speed >= sprint_speed_threshold:
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
	footstep_audio.play()
