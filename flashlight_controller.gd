
class_name FlashlightController
extends SpotLight3D

@export_group("Flashlight Settings")
@export var test_flashlight_unlocked: bool = true

@export_group("Audio")
@export var toggle_sound: AudioStreamPlayer

var has_flashlight: bool = false


func _ready() -> void:
	has_flashlight = FlashlightState.acquired or test_flashlight_unlocked

	if not has_flashlight:
		FlashlightState.turned_on = false

	visible = has_flashlight and FlashlightState.turned_on

	print("FLASHLIGHT: Ready. Acquired = ", has_flashlight)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("flashlight"):
		return

	if event is InputEventKey and event.echo:
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var player: CharacterBody3D = get_parent().get_parent() as CharacterBody3D

	if player != null and player.get("cutscene_locked") == true:
		return

	toggle_flashlight()
	get_viewport().set_input_as_handled()


func toggle_flashlight() -> void:
	if not has_flashlight:
		print("FLASHLIGHT: Not acquired yet.")
		return

	FlashlightState.turned_on = not FlashlightState.turned_on
	visible = FlashlightState.turned_on

	if toggle_sound != null and toggle_sound.stream != null:
		toggle_sound.play()

	print("FLASHLIGHT: ", "ON" if visible else "OFF")


func acquire_flashlight() -> void:
	if has_flashlight and FlashlightState.acquired:
		return

	has_flashlight = true
	FlashlightState.acquired = true

	print("FLASHLIGHT ACQUIRED. Press T to toggle.")
