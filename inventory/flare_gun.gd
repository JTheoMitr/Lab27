
extends Node3D

@export_group("References")
@export var player: CharacterBody3D
@export var player_camera: Camera3D
@export var projectile_scene: PackedScene


@export_group("Aim Down Sights")
@export var hand_offset: Node3D

@export var aim_position_offset: Vector3 = Vector3(-0.12, 0.08, 0.18)
@export var aim_rotation_offset: Vector3 = Vector3.ZERO
@export var aim_transition_speed: float = 0.2

var normal_hand_position: Vector3
var normal_hand_rotation: Vector3
var aim_tween: Tween




var is_aiming: bool = false
var is_holstering: bool = false


@export_group("Testing")
@export var test_weapon_unlocked: bool = true

@export_group("Weapon Settings")
@export var starting_ammo: int = 30
@export var fire_cooldown: float = 0.8

@onready var gun_model: Node3D = $GunModel
@onready var muzzle: Marker3D = $Muzzle
@onready var fire_sound: AudioStreamPlayer3D = $FireSound


@export_group("Weapon Animations")
@export var hand_animation_player: AnimationPlayer

@export var draw_animation: StringName = &"knife_draw"
@export var idle_animation: StringName = &"flare_gun_idle"
@export var aim_animation: StringName = &"flare_gun_idle"
@export var fire_animation: StringName = &"finger_gun_fire"

var weapon_animating: bool = false


var has_flare_gun: bool = false
var equipped: bool = false
var ammo: int = 0
var can_fire: bool = true


func _ready() -> void:

	
	if hand_offset != null:
		normal_hand_position = hand_offset.position
		normal_hand_rotation = hand_offset.rotation
	
	if hand_animation_player != null:
		if not hand_animation_player.animation_finished.is_connected(
			_on_weapon_animation_finished
		):
			hand_animation_player.animation_finished.connect(
				_on_weapon_animation_finished
			)


	has_flare_gun = test_weapon_unlocked
	ammo = starting_ammo

	gun_model.hide()

	print("Flare gun ready. Ammo: ", ammo)


func _unhandled_input(event: InputEvent) -> void:
	if player == null or player_camera == null:
		return

	if player.get("cutscene_locked") == true:
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
		
	


	# AIM DOWN SIGHTS
	if event.is_action_pressed("aim"):
		if equipped and not is_holstering:
			is_aiming = true
			move_to_aim_position()

		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("aim"):
		if equipped and not is_holstering:
			is_aiming = false
			return_to_normal_position()

		get_viewport().set_input_as_handled()
		return




	# Press 2 to equip or holster.
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_2:
			toggle_weapon()
			get_viewport().set_input_as_handled()
			return

	# Left click fires the equipped weapon.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if equipped:
				# Do not shoot while actively using S4 hacking.
				if Input.is_action_pressed("hack_mode"):
					return

				fire()
				get_viewport().set_input_as_handled()





func toggle_weapon() -> void:
	if not has_flare_gun or weapon_animating:
		return

	if not equipped:
		# -------------------------
		# DRAW WEAPON
		# -------------------------
		
		equipped = true
		is_holstering = false
		is_aiming = false
		return_to_normal_position()

		gun_model.show()

		if hand_animation_player != null and hand_animation_player.has_animation(draw_animation):
			play_weapon_action(draw_animation)
		else:
			play_weapon_idle()

		print("Flare gun drawing.")

	else:
		# -------------------------
		# HOLSTER WEAPON
		# -------------------------
		is_aiming = false
		return_to_normal_position()

		if hand_animation_player != null and hand_animation_player.has_animation(draw_animation):
			weapon_animating = true
			is_holstering = true

			# Play knife_draw from end to beginning.
			hand_animation_player.play_backwards(draw_animation, 0.15)

			print("Flare gun holstering.")
		else:
			finish_holster()





func fire() -> void:
	if not equipped or not has_flare_gun:
		return

	if not can_fire or ammo <= 0:
		print("Flare gun: Empty or cooling down.")
		return

	if projectile_scene == null:
		push_error("Flare gun: Projectile scene not assigned.")
		return
		
	if weapon_animating:
		return

	var world_scene: Node = get_tree().current_scene

	if world_scene == null:
		push_error("Flare gun: No current scene available.")
		return

	can_fire = false
	ammo -= 1

	var projectile: Node3D = projectile_scene.instantiate() as Node3D

	if projectile == null:
		push_error("Flare gun: Projectile root must be Node3D.")
		ammo += 1
		can_fire = true
		return

	world_scene.add_child(projectile)

	# Use the camera's forward direction for aiming.
	var flare_direction: Vector3 = get_flare_direction()

	projectile.launch(
		muzzle.global_position,
		flare_direction,
		player
	)
	
	
	# Play the firing hand animation.
	if hand_animation_player != null and hand_animation_player.has_animation(fire_animation):
		play_weapon_action(fire_animation)
	else:
		push_warning("Flare gun: Fire animation unavailable.")


	if fire_sound.stream != null:
		fire_sound.play()

	print("Flare fired! Remaining ammo: ", ammo)

	await get_tree().create_timer(fire_cooldown).timeout

	can_fire = true


func acquire_flare_gun() -> void:
	if has_flare_gun:
		return

	has_flare_gun = true
	ammo = starting_ammo

	print("FLARE GUN ACQUIRED. Ammo: ", ammo)



func play_weapon_idle() -> void:
	if hand_animation_player == null:
		return

	if not hand_animation_player.has_animation(idle_animation):
		push_warning("Flare gun: Idle animation not found: " + str(idle_animation))
		return

	var animation: Animation = hand_animation_player.get_animation(idle_animation)
	animation.loop_mode = Animation.LOOP_LINEAR

	weapon_animating = false

	hand_animation_player.play(idle_animation, 0.55)

	print("Flare gun: Idle animation playing.")



func play_weapon_action(animation_name: StringName) -> void:
	if hand_animation_player == null:
		return

	if not hand_animation_player.has_animation(animation_name):
		push_warning("Flare gun: Animation not found: " + str(animation_name))
		return

	var animation: Animation = hand_animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_NONE

	weapon_animating = true
	hand_animation_player.play(animation_name, 0.1)

	print("Flare gun: Playing ", animation_name)




func _on_weapon_animation_finished(animation_name: StringName) -> void:
	# Finish holstering after the reverse draw animation.
	if is_holstering:
		if animation_name == draw_animation:
			finish_holster()
		return

	if not equipped:
		return

	# Return to the normal holding animation after drawing or firing.
	if animation_name == draw_animation or animation_name == fire_animation:
		weapon_animating = false
		play_weapon_idle()


func play_weapon_aim() -> void:
	if hand_animation_player == null:
		return

	if not hand_animation_player.has_animation(aim_animation):
		push_warning("Flare gun: Aim animation not found: " + str(aim_animation))
		return

	var animation: Animation = hand_animation_player.get_animation(aim_animation)
	animation.loop_mode = Animation.LOOP_LINEAR

	hand_animation_player.play(aim_animation, 0.15)

	print("Flare gun: Aiming.")



func finish_holster() -> void:
	is_holstering = false
	is_aiming = false
	weapon_animating = false
	equipped = false

	gun_model.hide()

	if hand_animation_player != null:
		hand_animation_player.stop()

	print("Flare gun holstered.")


func move_to_aim_position() -> void:
	if not equipped or is_holstering or hand_offset == null:
		return

	if aim_tween != null:
		aim_tween.kill()

	aim_tween = create_tween()
	aim_tween.set_parallel(true)
	aim_tween.set_trans(Tween.TRANS_SINE)
	aim_tween.set_ease(Tween.EASE_IN_OUT)

	aim_tween.tween_property(
		hand_offset,
		"position",
		normal_hand_position + aim_position_offset,
		aim_transition_speed
	)

	aim_tween.tween_property(
		hand_offset,
		"rotation",
		normal_hand_rotation + Vector3(
			deg_to_rad(aim_rotation_offset.x),
			deg_to_rad(aim_rotation_offset.y),
			deg_to_rad(aim_rotation_offset.z)
		),
		aim_transition_speed
	)


func return_to_normal_position() -> void:
	if hand_offset == null:
		return

	if aim_tween != null:
		aim_tween.kill()

	aim_tween = create_tween()
	aim_tween.set_parallel(true)
	aim_tween.set_trans(Tween.TRANS_SINE)
	aim_tween.set_ease(Tween.EASE_IN_OUT)

	aim_tween.tween_property(
		hand_offset,
		"position",
		normal_hand_position,
		aim_transition_speed
	)

	aim_tween.tween_property(
		hand_offset,
		"rotation",
		normal_hand_rotation,
		aim_transition_speed
	)



func get_flare_direction() -> Vector3:
	var camera_origin: Vector3 = player_camera.global_position
	var camera_forward: Vector3 = -player_camera.global_transform.basis.z

	var max_distance: float = 100.0
	var target_position: Vector3 = camera_origin + camera_forward * max_distance

	# Find what the center of the camera is looking at.
	var query := PhysicsRayQueryParameters3D.create(
		camera_origin,
		target_position,
		3
	)

	# Ignore the player's collision capsule.
	query.exclude = [player.get_rid()]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if not hit.is_empty():
		target_position = hit["position"]

		print("FLARE AIM TARGET: ", hit["collider"].name)
		print("FLARE AIM POSITION: ", target_position)
	else:
		print("FLARE AIM: No surface detected. Aiming forward.")

	# Launch from the actual muzzle toward the camera target.
	var muzzle_position: Vector3 = muzzle.global_position
	var direction: Vector3 = target_position - muzzle_position

	if direction.length_squared() < 0.0001:
		return camera_forward

	print("FLARE MUZZLE POSITION: ", muzzle_position)
	print("FLARE LAUNCH DIRECTION: ", direction.normalized())

	return direction.normalized()
