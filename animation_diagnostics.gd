
extends Node

@export var animation_player: AnimationPlayer


func _ready() -> void:
	if animation_player == null:
		push_warning("DIAGNOSTIC: Assign the AnimationPlayer!")
		return

	print("========== ANIMATION DIAGNOSTIC START ==========")

	var checked_keys: int = 0
	var invalid_keys: int = 0

	for animation_name in animation_player.get_animation_list():
		var animation: Animation = animation_player.get_animation(animation_name)

		for track_index in range(animation.get_track_count()):
			if animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
				continue

			var track_path: NodePath = animation.track_get_path(track_index)

			for key_index in range(animation.track_get_key_count(track_index)):
				checked_keys += 1

				var rotation: Quaternion = animation.track_get_key_value(
					track_index,
					key_index
				)

				if not rotation.is_normalized():
					invalid_keys += 1

					print(
						"INVALID ROTATION | Animation: ",
						animation_name,
						" | Bone track: ",
						track_path,
						" | Key: ",
						key_index,
						" | Time: ",
						animation.track_get_key_time(track_index, key_index),
						" | Quaternion: ",
						rotation
					)

	print("Checked rotation keys: ", checked_keys)
	print("Invalid rotation keys: ", invalid_keys)
	print("========== ANIMATION DIAGNOSTIC END ==========")
