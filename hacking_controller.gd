
extends Node

@export var hacking_ray: RayCast3D
@export var hacking_reticle: Control

@export var hand_offset_node: Node3D


@export_group("Hand Animation")
@export var hand_animation_player: AnimationPlayer
@export var hand_animation_name: StringName = &""
@export var hand_reach_time: float = 0.5


@export_group("Hand Tremor")
@export var hand_shake_enabled: bool = true
@export var hand_shake_amount: float = 0.006
@export var hand_shake_speed: float = 18.0

var hand_shake_time: float = 0.0
var hand_shake_offset: Vector3 = Vector3.ZERO


@export var hacking_hand_rotation: Vector3 = Vector3(0.0, 25.0, 0.0)
@export var hand_rotation_transition: float = 0.25

var hand_original_rotation: Vector3
var hand_rotation_tween: Tween

var hand_extended: bool = false
var hand_retracting: bool = false


var hacking_mode: bool = false
var charge_completed: bool = false
var current_target: Node3D = null


func _ready() -> void:
	
	if hand_offset_node != null:
		hand_original_rotation = hand_offset_node.rotation_degrees
		
	if hacking_ray == null or hacking_reticle == null:
		push_error("Hacking controller: Assign HackingRay and HackingReticle!")
		set_process(false)
		return

	hacking_reticle.visible = false

	hacking_reticle.connect(
		"hack_charge_complete",
		_on_hack_charge_complete
	)


func _process(_delta: float) -> void:
	
	update_hacking_hand()
	var holding_q: bool = Input.is_action_pressed("hack_mode")

	if not holding_q:
		if hacking_mode:
			exit_hacking_mode()
		return

	if not hacking_mode:
		enter_hacking_mode()

	if charge_completed:
		return

	update_hacking_target()
	update_hacking_hand_shake(_delta)

	if current_target != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		hacking_reticle.call("start_charge")
	else:
		hacking_reticle.call("cancel_charge")


func enter_hacking_mode() -> void:
	
	set_hacking_hand_rotation(true)
	hacking_mode = true
	charge_completed = false
	hacking_reticle.visible = true
	
	extend_hacking_hand()

	print("Hacking mode activated")


func exit_hacking_mode() -> void:
	
	set_hacking_hand_rotation(false)
	hacking_mode = false
	charge_completed = false
	current_target = null

	hacking_reticle.visible = false
	hacking_reticle.call("set_targeting", false)
	hacking_reticle.call("cancel_charge")
	
	retract_hacking_hand()

	print("Hacking mode deactivated")


func update_hacking_target() -> void:
	hacking_ray.force_raycast_update()

	var detected_target: Node3D = null

	if hacking_ray.is_colliding():
		var collider: Object = hacking_ray.get_collider()

		if collider is Area3D:
			var device: Node = collider.get_parent()

			if device is Node3D and device.has_method("begin_hack"):
				detected_target = device

	if detected_target != current_target:
		current_target = detected_target
		hacking_reticle.call("cancel_charge")

	hacking_reticle.call("set_targeting", current_target != null)


func _on_hack_charge_complete() -> void:
	if current_target == null or not hacking_mode:
		return

	charge_completed = true

	print("Hack charge completed: ", current_target.name)

	current_target.call("begin_hack")
	
	


func extend_hacking_hand() -> void:
	if hand_animation_player == null:
		push_warning("Hacking hand: No AnimationPlayer assigned!")
		return

	if hand_animation_name == &"":
		push_warning("Hacking hand: No animation name assigned!")
		return

	if not hand_animation_player.has_animation(hand_animation_name):
		push_warning("Hacking hand: Animation not found: " + str(hand_animation_name))
		print("Available animations: ", hand_animation_player.get_animation_list())
		return

	hand_extended = false
	hand_retracting = false

	hand_animation_player.play(hand_animation_name)

	print("Hacking hand animation started: ", hand_animation_name)



func retract_hacking_hand() -> void:
	if hand_animation_player == null:
		return

	if not hand_animation_player.has_animation(hand_animation_name):
		return

	hand_extended = false
	hand_retracting = true

	# Resume the remaining portion of the original animation.
	if hand_animation_player.current_animation != hand_animation_name:
		hand_animation_player.play(hand_animation_name)
	elif not hand_animation_player.is_playing():
		hand_animation_player.play()



func update_hacking_hand() -> void:
	if hand_animation_player == null:
		return

	if hand_animation_name == &"":
		return

	if not hand_animation_player.has_animation(hand_animation_name):
		return

	if hand_retracting:
		if not hand_animation_player.is_playing():
			hand_retracting = false
		return

	if not hacking_mode or hand_extended:
		return

	# Do not read playback position unless an animation is active.
	if hand_animation_player.current_animation == &"":
		return

	if not hand_animation_player.is_playing():
		return

	if hand_animation_player.current_animation_position >= hand_reach_time:
		hand_animation_player.seek(hand_reach_time, true)
		hand_animation_player.pause()
		hand_extended = true

func set_hacking_hand_rotation(active: bool) -> void:
	if hand_offset_node == null:
		return

	if hand_rotation_tween != null:
		hand_rotation_tween.kill()

	var target_rotation: Vector3 = hand_original_rotation

	if active:
		target_rotation += hacking_hand_rotation

	hand_rotation_tween = create_tween()
	hand_rotation_tween.set_trans(Tween.TRANS_SINE)
	hand_rotation_tween.set_ease(Tween.EASE_IN_OUT)
	hand_rotation_tween.tween_property(
		hand_offset_node,
		"rotation_degrees",
		target_rotation,
		hand_rotation_transition
	)

func update_hacking_hand_shake(delta: float) -> void:
	if hand_offset_node == null:
		return

	# Remove the shake applied on the previous frame.
	hand_offset_node.position -= hand_shake_offset
	hand_shake_offset = Vector3.ZERO

	# Shake only while actively charging a hack.
	if not hand_shake_enabled or not hacking_mode or not hand_extended or not hacking_reticle.charging:
		hand_shake_time = 0.0
		return

	hand_shake_time += delta * hand_shake_speed

	# Combine several sine waves for a natural, irregular tremor.
	var shake_x: float = sin(hand_shake_time * 1.7)
	var shake_y: float = sin(hand_shake_time * 2.3 + 1.2)
	var shake_z: float = sin(hand_shake_time * 1.1 + 2.4)

	hand_shake_offset = Vector3(
		shake_x,
		shake_y,
		shake_z * 0.35
	) * hand_shake_amount

	hand_offset_node.position += hand_shake_offset
