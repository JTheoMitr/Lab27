
extends Node3D

@export_group("References")
@export var player: CharacterBody3D
@export var chip_model: Node3D
@export var install_sound: AudioStreamPlayer

@export_group("Pickup Settings")
@export var max_pickup_distance: float = 2.0
@export var grab_animation: StringName = &"grab_R"
@export var pickup_disappear_delay: float = 0.4
@export var installation_pause: float = 0.1

@export var activation_overlay: S4ActivationOverlay


var pickup_started: bool = false


func _ready() -> void:
	if S4State.installed:
		queue_free()


func interact() -> void:
	if pickup_started or S4State.installed:
		return

	if player == null or chip_model == null:
		push_warning("S4-MYND: Missing player or chip reference.")
		return

	var distance: float = player.global_position.distance_to(global_position)

	if distance > max_pickup_distance:
		print("S4-MYND: Move closer.")
		return

	if not player.has_method("set_cutscene_locked"):
		push_error("S4-MYND: Player is missing cutscene lock method.")
		return

	pickup_started = true
	start_installation()


func start_installation() -> void:
	print("S4-MYND: Installation started.")

	player.set_cutscene_locked(true)

	# Use the player's existing first-person hand animation.
	var hand_anim: AnimationPlayer = player.get_node(
		"Camera3D/HandOffset/arms_rig/AnimationPlayer"
	)

	var has_grab_animation: bool = hand_anim.has_animation(grab_animation)

	if has_grab_animation:
		var animation: Animation = hand_anim.get_animation(grab_animation)
		animation.loop_mode = Animation.LOOP_NONE

		hand_anim.play(grab_animation)
	else:
		push_warning("S4-MYND: Grab animation not found: " + str(grab_animation))

	# Wait for the hand to reach the chip.
	await get_tree().create_timer(pickup_disappear_delay).timeout

	chip_model.hide()

	# Wait for the grab animation to finish.
	if has_grab_animation and hand_anim.is_playing():
		await hand_anim.animation_finished


	# -------------------------
	# STAGE 4: IMPLANT SOUND
	# -------------------------

	if install_sound != null and install_sound.stream != null:
		# Flash red at the exact moment implantation begins.
		if activation_overlay != null:
			activation_overlay.play_implant_flash()

		install_sound.play()
		await install_sound.finished

	# Short silence after implantation.
	await get_tree().create_timer(installation_pause).timeout

	# -------------------------
	# STAGE 5: NEURAL ACTIVATION
	# -------------------------

	print("S4-MYND: Activating neural interface.")

	if activation_overlay != null:
		activation_overlay.play_activation()
		await activation_overlay.activation_finished
	else:
		push_warning("S4-MYND: Activation overlay not assigned.")

	# -------------------------
	# STAGE 6: UNLOCK HACKING
	# -------------------------

	S4State.installed = true

	player.set_cutscene_locked(false)

	print("S4-MYND INSTALLED. HACKING ONLINE.")

	queue_free()
