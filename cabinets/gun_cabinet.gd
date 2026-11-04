
extends Node3D

@export_group("Cabinet Settings")
@export var is_locked: bool = true
@export var opening_animation: StringName = &"loop"
@export_range(0.0, 1.0, 0.01) var open_stop_fraction: float = 0.75

@export_group("References")
@export var animation_player: AnimationPlayer
@export var interaction_area: Area3D
@export var contents: Node3D

var is_open: bool = false
var is_opening: bool = false
var stop_time: float = 0.0


func _ready() -> void:
	set_process(false)
	add_to_group("gun_cabinet")

	if animation_player == null:
		push_error("GunCabinet: AnimationPlayer not assigned.")
		return

	if not animation_player.has_animation(opening_animation):
		push_error("GunCabinet: Opening animation not found.")
		return

	var animation: Animation = animation_player.get_animation(opening_animation)
	stop_time = animation.length * open_stop_fraction

	# Begin with the cabinet fully closed.
	animation_player.play(opening_animation)
	animation_player.seek(0.0, true)
	animation_player.pause()

	if contents != null:
		contents.hide()

	print("Cabinet ready. Stop time: ", stop_time)

func is_interactable() -> bool:
	return not is_open and not is_opening

func interact(has_key: bool = false) -> void:
	print("CABINET: interact() called!")
	print("CABINET: is_locked = ", is_locked)
	print("CABINET: is_open = ", is_open)
	print("CABINET: is_opening = ", is_opening)

	if is_open or is_opening:
		print("CABINET: Interaction blocked by current state!")
		return

	if is_locked:
		if not has_key:
			print("CABINET: Missing key!")
			return

		is_locked = false
		print("CABINET: Unlocked!")

	open_cabinet()



func open_cabinet() -> void:
	is_opening = true

	print("Cabinet opening!")

	# Restart at the beginning, even if previously paused.
	animation_player.play(opening_animation)
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)

	# Let Godot play the animation normally.
	set_process(true)


func _process(_delta: float) -> void:
	if not is_opening:
		return

	if animation_player.current_animation_position >= stop_time:
		# Freeze the cabinet in the fully open pose.
		animation_player.pause()
		animation_player.seek(stop_time, true)

		is_open = true
		is_opening = false
		set_process(false)

		if contents != null:
			contents.show()

		print("Cabinet opened and held at ", stop_time, " seconds.")
