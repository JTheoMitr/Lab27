
extends Node3D

@export var door: Node3D
@export var window_pane: Node3D
@export var door_body: AnimatableBody3D

@export var open_angle: float = 90.0
@export var open_duration: float = 0.8


@export_group("Security")
@export var starts_locked: bool = false

var is_locked: bool = false


var is_open := false
var is_moving := false

var closed_angle: float
var window_closed_angle: float
var body_closed_angle: float


func _ready() -> void:
	
	is_locked = starts_locked
	
	if door == null or window_pane == null or door_body == null:
		push_warning("Door, window, or collision body not assigned!")
		return

	closed_angle = door.rotation_degrees.z
	window_closed_angle = window_pane.rotation_degrees.z
	body_closed_angle = door_body.rotation_degrees.z


func interact() -> void:
	
	if is_locked:
		print("ACCESS DENIED: Door is locked.")
		return
		
	if is_moving or door == null or window_pane == null or door_body == null:
		return

	is_moving = true
	is_open = not is_open

	var angle_offset = open_angle if is_open else 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	tween.tween_property(
		door,
		"rotation_degrees:z",
		closed_angle + angle_offset,
		open_duration
	)

	tween.tween_property(
		window_pane,
		"rotation_degrees:z",
		window_closed_angle + angle_offset,
		open_duration
	)

	tween.tween_property(
		door_body,
		"rotation_degrees:z",
		body_closed_angle + angle_offset,
		open_duration
	)

	await tween.finished
	is_moving = false
	
	

func unlock_door() -> void:
	if not is_locked:
		return

	is_locked = false

	print("Door security disabled: ", name)
	

func lock_door() -> void:
	if is_locked:
		return

	is_locked = true
	print("Door locked by keypad: ", name)
