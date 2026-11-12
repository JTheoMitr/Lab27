
extends Node3D

@export_group("References")
@export var player: CharacterBody3D
@export var flare_gun: Node3D
@export var flare_gun_model: Node3D

@export_group("Item Discovery")
@export var discovery_ui: ItemDiscoveryUI
@export var preview_scene: PackedScene
@export var preview_scale: float = 1.0
@export var preview_offset: Vector3 = Vector3.ZERO

@export_group("Tutorial Animation")
@export var tutorial_frames: SpriteFrames
@export var tutorial_animation: StringName = &"default"

@export_group("Pickup Settings")
@export var max_pickup_distance: float = 2.0
@export var grab_animation: StringName = &"grab_R"
@export var pickup_disappear_delay: float = 0.4

@export var cabinet: Node3D

var pickup_started: bool = false


func interact() -> void:
	if pickup_started:
		return
		
	
	# Prevent collecting the weapon before the cabinet is accessible.
	if cabinet != null:
		if cabinet.get("pickup_available") != true:
			print("FLARE PICKUP: Cabinet not open enough yet.")
			return


	if player == null or flare_gun == null or flare_gun_model == null:
		push_warning("Flare gun pickup: Missing references.")
		return

	if player.get("cutscene_locked") == true:
		return

	var player_camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D

	if player_camera == null:
		push_error("Flare gun pickup: Player camera not found.")
		return

	var distance: float = player_camera.global_position.distance_to(
		flare_gun_model.global_position
	)

	if distance > max_pickup_distance:
		print("FLARE GUN: Move closer.")
		return

	var hand_anim: AnimationPlayer = player.get_node_or_null(
		"Camera3D/HandOffset/arms_rig/AnimationPlayer"
	) as AnimationPlayer

	if hand_anim == null:
		push_error("Flare gun pickup: Hand AnimationPlayer not found.")
		return

	if not hand_anim.has_animation(grab_animation):
		push_error("Flare gun pickup: Missing grab animation.")
		return

	if not player.has_method("set_cutscene_locked"):
		push_error("Flare gun pickup: Player has no cutscene lock method.")
		return

	pickup_started = true
	play_pickup_animation(hand_anim)


func play_pickup_animation(hand_anim: AnimationPlayer) -> void:
	player.set_cutscene_locked(true)

	# Play the same right-hand grab animation as the flashlight.
	var animation: Animation = hand_anim.get_animation(grab_animation)
	animation.loop_mode = Animation.LOOP_NONE

	hand_anim.play(grab_animation)

	await get_tree().create_timer(pickup_disappear_delay).timeout

	# The physical gun disappears when the hand reaches it.
	if is_instance_valid(flare_gun_model):
		flare_gun_model.hide()

	# Wait for the grab animation to finish.
	if hand_anim.is_playing() and hand_anim.current_animation == grab_animation:
		await hand_anim.animation_finished

	# Unlock the equipped flare gun.
	if flare_gun.has_method("acquire_flare_gun"):
		flare_gun.acquire_flare_gun()

	# Show the reusable discovery popup.
	if discovery_ui != null:
		discovery_ui.show_item(
			preview_scene,
			"FLARE GUN",
			"An emergency signal launcher. Its burning projectiles can illuminate dark areas.",
			"FLARE GUN CONTROLS",
			"Press 2 to equip or holster.\nHold V to aim down sights.\nLeft-click to fire.",
			preview_scale,
			preview_offset,
			tutorial_frames,
			tutorial_animation
		)

		await discovery_ui.presentation_finished

	player.set_cutscene_locked(false)

	print("FLARE GUN: Pickup complete.")

	queue_free()
