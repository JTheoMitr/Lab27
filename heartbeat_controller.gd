
extends Node

@export_group("References")
@export var enemy: CharacterBody3D

@onready var heartbeat: AudioStreamPlayer = $Heartbeat

@export_group("Volume")
@export var quiet_volume_db: float = -7.0
@export var loud_volume_db: float = 5.0
@export var fade_in_speed: float = 1.5
@export var fade_out_speed: float = 0.6

var current_intensity: float = 0.0


func _ready() -> void:
	heartbeat.volume_db = -80.0
	heartbeat.pitch_scale = 1.0


func _process(delta: float) -> void:
	if not is_instance_valid(enemy):
		return

	var threat: float = enemy.get_heartbeat_threat()

	var fade_speed: float = fade_in_speed if threat > current_intensity else fade_out_speed

	current_intensity = move_toward(
		current_intensity,
		threat,
		fade_speed * delta
	)

	if threat > 0.0 and not heartbeat.playing:
		heartbeat.play()

	if current_intensity > 0.01:
		heartbeat.volume_db = lerpf(
			quiet_volume_db,
			loud_volume_db,
			current_intensity
		)
	else:
		heartbeat.volume_db = -80.0

		if heartbeat.playing:
			heartbeat.stop()
