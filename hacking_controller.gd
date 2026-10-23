
extends Node

@export var hacking_ray: RayCast3D
@export var hacking_reticle: Control

var hacking_mode: bool = false
var charge_completed: bool = false
var current_target: Node3D = null


func _ready() -> void:
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

	if current_target != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		hacking_reticle.call("start_charge")
	else:
		hacking_reticle.call("cancel_charge")


func enter_hacking_mode() -> void:
	hacking_mode = true
	charge_completed = false
	hacking_reticle.visible = true

	print("Hacking mode activated")


func exit_hacking_mode() -> void:
	hacking_mode = false
	charge_completed = false
	current_target = null

	hacking_reticle.visible = false
	hacking_reticle.call("set_targeting", false)
	hacking_reticle.call("cancel_charge")

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
