
extends Node3D

@export_group("References")
@export var player: CharacterBody3D
@export var key_model: Node3D
@export var discovery_ui: ItemDiscoveryUI

@export_group("Item Discovery")
@export var preview_scene: PackedScene
@export var preview_scale: float = 1.0
@export var preview_offset: Vector3 = Vector3.ZERO

@export_group("Pickup Settings")
@export var max_pickup_distance: float = 2.0
@export var grab_animation: StringName = &"grab_R"
@export var pickup_disappear_delay: float = 0.4

var pickup_started: bool = false


func _ready() -> void:
	# Do not respawn an already collected key.
	if KeyState.gun_cabinet_key:
		queue_free()


func interact() -> void:
	if pickup_started or KeyState.gun_cabinet_key:
		return

	if player == null or key_model == null:
		push_warning("KEY PICKUP: Missing player or model reference.")
		return

	if player.get("cutscene_locked") == true:
		return

	var player_camera: Camera3D = player.get_node_or_null(
		"Camera3D"
	) as Camera3D

	if player_camera == null:
		push_error("KEY PICKUP: Player camera not found.")
		return

	var distance: float = player_camera.global_position.distance_to(
		key_model.global_position
	)

	if distance > max_pickup_distance:
		print("KEY PICKUP: Move closer.")
		return

	var hand_anim: AnimationPlayer = player.get_node_or_null(
		"Camera3D/HandOffset/arms_rig/AnimationPlayer"
	) as AnimationPlayer

	if hand_anim == null:
		push_error("KEY PICKUP: Hand AnimationPlayer not found.")
		return

	if not hand_anim.has_animation(grab_animation):
		push_error("KEY PICKUP: Grab animation missing.")
		return

	if not player.has_method("set_cutscene_locked"):
		push_error("KEY PICKUP: Player has no cutscene lock method.")
		return

	pickup_started = true
	play_pickup_animation(hand_anim)


func play_pickup_animation(hand_anim: AnimationPlayer) -> void:
	print("KEY PICKUP: Starting pickup.")

	player.set_cutscene_locked(true)

	var animation: Animation = hand_anim.get_animation(grab_animation)
	animation.loop_mode = Animation.LOOP_NONE

	hand_anim.play(grab_animation)

	# Make the physical key disappear when the hand reaches it.
	await get_tree().create_timer(pickup_disappear_delay).timeout

	if is_instance_valid(key_model):
		key_model.hide()

	# Wait for the grab animation to finish.
	if hand_anim.is_playing() and hand_anim.current_animation == grab_animation:
		await hand_anim.animation_finished

	# Record ownership.
	KeyState.gun_cabinet_key = true

	print("KEY ACQUIRED: Gun cabinet key.")

	# Show the rotating key with no tutorial page.
	if discovery_ui != null:
		discovery_ui.show_item(
			preview_scene,
			"GUN CABINET KEY",
			"A small metal key labeled 'Emergency Equipment'. It may unlock a cabinet somewhere in the facility.",
			"",
			"",
			preview_scale,
			preview_offset
		)

		await discovery_ui.presentation_finished

	player.set_cutscene_locked(false)

	print("KEY PICKUP: Complete.")

	queue_free()
