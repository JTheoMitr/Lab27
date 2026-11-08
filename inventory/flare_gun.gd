
extends Node3D

@export_group("References")
@export var player: CharacterBody3D
@export var player_camera: Camera3D
@export var projectile_scene: PackedScene

@export_group("Testing")
@export var test_weapon_unlocked: bool = true

@export_group("Weapon Settings")
@export var starting_ammo: int = 2
@export var fire_cooldown: float = 0.8

@onready var gun_model: Node3D = $GunModel
@onready var muzzle: Marker3D = $Muzzle
@onready var fire_sound: AudioStreamPlayer3D = $FireSound

var has_flare_gun: bool = false
var equipped: bool = false
var ammo: int = 0
var can_fire: bool = true


func _ready() -> void:
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
	if not has_flare_gun:
		print("Flare gun not acquired.")
		return

	equipped = not equipped
	gun_model.visible = equipped

	print("Flare gun equipped: ", equipped)


func fire() -> void:
	if not equipped or not has_flare_gun:
		return

	if not can_fire or ammo <= 0:
		print("Flare gun: Empty or cooling down.")
		return

	if projectile_scene == null:
		push_error("Flare gun: Projectile scene not assigned.")
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
	var forward: Vector3 = -player_camera.global_transform.basis.z

	projectile.launch(
		muzzle.global_position,
		forward,
		player
	)

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
