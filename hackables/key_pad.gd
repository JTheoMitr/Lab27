
extends Node3D

signal hack_completed

@export_group("Security")
@export var starts_locked: bool = true
@export var unlock_nearby_doors: bool = true

@export_group("Debug")
@export var debug_keypad: bool = true

@onready var screen_red: MeshInstance3D = $ScreenRed
@onready var screen_green: MeshInstance3D = $ScreenGreen
@onready var unlock_zone: Area3D = $UnlockZone
@onready var success_sound: AudioStreamPlayer3D = $SuccessSound

var is_locked: bool = true
var controlled_doors: Array[Node] = []


func _ready() -> void:
	is_locked = starts_locked

	update_screen()

	call_deferred("_initialize_doors")


func _initialize_doors() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

	register_nearby_doors()

	if is_locked:
		for door in controlled_doors:
			if is_instance_valid(door):
				door.call("lock_door")

	if debug_keypad:
		print("KEYPAD INITIALIZED: ", name)
		print("Locked: ", is_locked)
		print("Doors connected: ", controlled_doors.size())


func register_nearby_doors() -> void:
	controlled_doors.clear()

	for body in unlock_zone.get_overlapping_bodies():
		var door: Node = find_door_controller(body)

		if door == null:
			continue

		if controlled_doors.has(door):
			continue

		controlled_doors.append(door)

		if debug_keypad:
			print("Keypad registered door: ", door.name)


func begin_hack() -> void:
	if not is_locked:
		if debug_keypad:
			print("Terminal already unlocked: ", name)
		return

	complete_hack()


func complete_hack() -> void:
	if not is_locked:
		return

	is_locked = false
	update_screen()

	if success_sound.stream != null:
		success_sound.play()

	if unlock_nearby_doors:
		unlock_controlled_doors()

	hack_completed.emit()

	if debug_keypad:
		print("HACK SUCCESSFUL: ", name)


func update_screen() -> void:
	screen_red.visible = is_locked
	screen_green.visible = not is_locked


func unlock_controlled_doors() -> void:
	for door in controlled_doors:
		if not is_instance_valid(door):
			continue

		door.call("unlock_door")

		if debug_keypad:
			print("Door unlocked: ", door.name)


func find_door_controller(start_node: Node) -> Node:
	var current: Node = start_node

	while current != null:
		if current.has_method("lock_door") and current.has_method("unlock_door"):
			return current

		current = current.get_parent()

	return null
