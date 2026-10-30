
extends Node3D

enum VocalMode {
	SILENT,
	CRYING,
	BREATHING,
	PANICKED
}

@export_group("Crying")
@export var crying_sounds: Array[AudioStream] = []
@export var crying_min_delay: float = 3.0
@export var crying_max_delay: float = 7.0

@export_group("Breathing")
@export var breathing_sounds: Array[AudioStream] = []
@export var breathing_min_delay: float = 0.5
@export var breathing_max_delay: float = 2.0

@export_group("Chasing")
@export var panic_sounds: Array[AudioStream] = []
@export var panic_min_delay: float = 0.2
@export var panic_max_delay: float = 0.8

@export_group("Volume")
@export var crying_volume_db: float = -9.0
@export var breathing_volume_db: float = -5.0
@export var panic_volume_db: float = 0.0

@export_group("Variation")
@export var minimum_pitch: float = 0.95
@export var maximum_pitch: float = 1.05

@export_group("Debug")
@export var debug_vocals: bool = false

@onready var vocal_audio: AudioStreamPlayer3D = $VocalAudio

var enemy: CharacterBody3D
var current_mode: VocalMode = VocalMode.SILENT
var next_vocal_timer: float = 0.0
var last_sample_index: int = -1


func _ready() -> void:
	enemy = get_parent() as CharacterBody3D

	if enemy == null or not enemy.has_method("get_vocal_mode"):
		push_error("CreatureVocals needs an SCP-096 parent with get_vocal_mode().")
		set_process(false)
		return

	schedule_next_vocal()


func _process(delta: float) -> void:
	if not is_instance_valid(enemy):
		return

	var requested_mode: VocalMode = enemy.get_vocal_mode()

	if requested_mode != current_mode:
		current_mode = requested_mode

		# Stop the previous vocal sound when the AI changes modes.
		vocal_audio.stop()
		next_vocal_timer = 0.0

		if debug_vocals:
			print("SCP VOCAL MODE: ", VocalMode.keys()[current_mode])

	if current_mode == VocalMode.SILENT:
		return

	if vocal_audio.playing:
		return

	next_vocal_timer -= delta

	if next_vocal_timer <= 0.0:
		play_vocal()
		schedule_next_vocal()


func schedule_next_vocal() -> void:
	match current_mode:
		VocalMode.CRYING:
			next_vocal_timer = randf_range(crying_min_delay, crying_max_delay)

		VocalMode.BREATHING:
			next_vocal_timer = randf_range(breathing_min_delay, breathing_max_delay)

		VocalMode.PANICKED:
			next_vocal_timer = randf_range(panic_min_delay, panic_max_delay)

		_:
			next_vocal_timer = 0.0


func play_vocal() -> void:
	var sounds: Array[AudioStream] = []
	var volume: float = 0.0

	match current_mode:
		VocalMode.CRYING:
			sounds = crying_sounds
			volume = crying_volume_db

		VocalMode.BREATHING:
			sounds = breathing_sounds
			volume = breathing_volume_db

		VocalMode.PANICKED:
			sounds = panic_sounds
			volume = panic_volume_db

	if sounds.is_empty():
		return

	var index: int = randi_range(0, sounds.size() - 1)

	if sounds.size() > 1:
		while index == last_sample_index:
			index = randi_range(0, sounds.size() - 1)

	last_sample_index = index

	vocal_audio.stream = sounds[index]
	vocal_audio.volume_db = volume
	vocal_audio.pitch_scale = randf_range(minimum_pitch, maximum_pitch)
	vocal_audio.play()

	if debug_vocals:
		print("SCP playing vocal sample: ", index)
