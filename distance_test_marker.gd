
extends Marker3D

@export var player: Node3D

var print_timer: float = 0.0


func _process(delta: float) -> void:
	if player == null:
		return

	print_timer += delta

	if print_timer >= 1.0:
		print_timer = 0.0

		var distance: float = global_position.distance_to(
			player.global_position
		)

		print("Distance from test marker: ", snappedf(distance, 0.1), " meters")
