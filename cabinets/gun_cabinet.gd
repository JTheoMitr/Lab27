
extends Node3D

@export_group("Cabinet Settings")
@export var is_locked: bool = true
@export var opening_animation: StringName = &"loop"
@export_range(0.0, 1.0, 0.01) var open_stop_fraction: float = 0.50

@export_group("References")
@export var animation_player: AnimationPlayer
@export var interaction_area: Area3D
@export var contents: Node3D

@export_range(0.0, 1.0, 0.01) var pickup_available_fraction: float = 0.15

var pickup_available: bool = false
var pickup_available_time: float = 0.0

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

	# Prevent the imported animation from looping.
	animation.loop_mode = Animation.LOOP_NONE

	stop_time = animation.length * open_stop_fraction
	pickup_available_time = animation.length * pickup_available_fraction

	# Start fully closed.
	animation_player.play(opening_animation)
	animation_player.seek(0.0, true)
	animation_player.pause()

	if contents != null:
		contents.hide()
		print("CABINET: Contents assigned: ", contents.get_path())
	else:
		push_warning("CABINET: Contents not assigned!")

	print("CABINET: Ready. Animation length = ", animation.length)
	print("CABINET: Stop time = ", stop_time)


func is_interactable() -> bool:
	return not is_open and not is_opening


func interact() -> void:
	print("CABINET: interact() called!")
	print("CABINET: Key acquired = ", KeyState.gun_cabinet_key)

	if is_open or is_opening:
		return

	if is_locked:
		if not KeyState.gun_cabinet_key:
			print("CABINET: Missing key!")
			return

		is_locked = false
		print("CABINET: Key accepted!")

	open_cabinet()



func open_cabinet() -> void:
	is_opening = true

	print("CABINET: Opening...")

	# Reveal the gun before the door begins moving.
	# The closed cabinet should physically conceal it.
	if contents != null:
		contents.show()
		print("CABINET: Contents revealed behind doors.")

	animation_player.play(opening_animation)
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)

	set_process(true)




func _process(_delta: float) -> void:
	if not is_opening:
		return

	var current_time: float = animation_player.current_animation_position

	# Make the flare gun collectible once the doors are sufficiently open.
	if not pickup_available and current_time >= pickup_available_time:
		pickup_available = true
		print("CABINET: Flare gun can now be collected.")

	if current_time >= stop_time:
		finish_opening()




func finish_opening() -> void:
	is_opening = false
	is_open = true
	set_process(false)

	# Freeze the cabinet at the open position.
	animation_player.seek(stop_time, true)
	animation_player.pause()

	print("CABINET: Animation stopped at ", stop_time)

	# Reveal the flare gun.
	if contents != null:
		contents.show()
		print("CABINET: Contents visible = ", contents.visible)

	# Disable the cabinet's interaction area now that it's open.
	# This allows the player's raycast to reach the flare gun.
	if interaction_area != null:
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = 0

		print("CABINET: Interaction area disabled.")

	print("CABINET: Open and ready for item pickup.")
