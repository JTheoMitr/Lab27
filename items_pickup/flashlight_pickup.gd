
extends Node3D

@export_group("References")
@export var player: CharacterBody3D
@export var flashlight_controller: FlashlightController
@export var flashlight_model: Node3D

@export_group("Pickup Settings")
@export var max_pickup_distance: float = 2.0
@export var grab_animation: StringName = &"grab_R"
@export var pickup_disappear_delay: float = 0.4


@export_group("Item Discovery")
@export var discovery_ui: ItemDiscoveryUI
@export var preview_scene: PackedScene
@export var preview_scale: float = 1.0
@export var preview_offset: Vector3 = Vector3.ZERO


@export_group("Tutorial Animation")
@export var tutorial_frames: SpriteFrames
@export var tutorial_animation: StringName = &"default"


var pickup_started: bool = false


func _ready() -> void:
	if FlashlightState.acquired:
		queue_free()


func interact() -> void:
	if pickup_started or FlashlightState.acquired:
		return

	if player == null or flashlight_controller == null or flashlight_model == null:
		push_warning("Flashlight pickup: Missing reference.")
		return

	if player.get("cutscene_locked") == true:
		return

	var player_camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D

	if player_camera == null:
		push_error("Flashlight pickup: Player camera not found.")
		return

	var distance: float = player_camera.global_position.distance_to(
		flashlight_model.global_position
	)

	if distance > max_pickup_distance:
		print("FLASHLIGHT: Move closer.")
		return

	if not player.has_method("set_cutscene_locked"):
		push_error("Flashlight pickup: Player missing cutscene lock method.")
		return

	var hand_anim: AnimationPlayer = player.get_node_or_null(
		"Camera3D/HandOffset/arms_rig/AnimationPlayer"
	) as AnimationPlayer

	if hand_anim == null:
		push_error("Flashlight pickup: Hand AnimationPlayer not found.")
		return

	if not hand_anim.has_animation(grab_animation):
		push_error("Flashlight pickup: Animation not found: " + str(grab_animation))
		return

	pickup_started = true
	play_pickup_animation(hand_anim)


func play_pickup_animation(hand_anim: AnimationPlayer) -> void:
	print("FLASHLIGHT: Pickup started.")

	player.set_cutscene_locked(true)

	var animation: Animation = hand_anim.get_animation(grab_animation)
	animation.loop_mode = Animation.LOOP_NONE

	hand_anim.play(grab_animation)

	# Wait until the player's hand reaches the flashlight.
	await get_tree().create_timer(pickup_disappear_delay).timeout

	if is_instance_valid(flashlight_model):
		flashlight_model.hide()

	# Wait until the grab animation has completed.
	if hand_anim.is_playing() and hand_anim.current_animation == grab_animation:
		await hand_anim.animation_finished

	
	# Unlock the flashlight.
	flashlight_controller.acquire_flashlight()

	# Display the item reveal while player movement remains locked.
	if discovery_ui != null:
		
		discovery_ui.show_item(
			preview_scene,
			"FLASHLIGHT",
			"A portable light source recovered from the facility.",
			"FLASHLIGHT CONTROLS",
			"Press F to toggle the flashlight on or off.",
			preview_scale,
			preview_offset,
			tutorial_frames,
			tutorial_animation
		)

		await discovery_ui.presentation_finished


	# Restore player controls after dismissal.
	player.set_cutscene_locked(false)

	print("FLASHLIGHT: Pickup complete.")

	queue_free()
