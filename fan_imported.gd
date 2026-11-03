
extends Node3D

@export var animation_player: AnimationPlayer
@export var animation_name: StringName = &"FanAction"

@export_group("Loop Segment")
@export var loop_start_time: float = 3.0
@export var loop_end_time: float = 5.73

@export_group("Playback")
@export_range(0.1, 30.0, 0.1) var playback_speed: float = 5.0

var playback_time: float = 0.0
var animation_length: float = 0.0


func _ready() -> void:
	if animation_player == null:
		push_warning("Fan: AnimationPlayer not assigned.")
		set_process(false)
		return

	if not animation_player.has_animation(animation_name):
		push_warning("Fan: Animation not found.")
		set_process(false)
		return

	var animation: Animation = animation_player.get_animation(animation_name)
	animation_length = animation.length

	loop_start_time = clampf(loop_start_time, 0.0, animation_length)
	loop_end_time = clampf(loop_end_time, loop_start_time, animation_length)

	if loop_end_time <= loop_start_time:
		push_warning("Fan: Invalid loop segment.")
		set_process(false)
		return

	playback_time = loop_start_time

	animation_player.play(animation_name)

	animation_player.pause()
	
	animation_player.seek(playback_time, true)


func _process(delta: float) -> void:
	var segment_length: float = loop_end_time - loop_start_time

	playback_time += delta * playback_speed

	if playback_time >= loop_end_time:
		playback_time = loop_start_time + fposmod(
			playback_time - loop_start_time,
			segment_length
		)

	animation_player.seek(playback_time, true)
