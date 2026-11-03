
extends Node3D

@onready var corner_boi = $CornerBoi

# -------------------------
# MUSIC
# -------------------------

@export_group("Music")
@export var music_target_volume_db: float = -8.0
@export var music_fade_in_duration: float = 3.0
@export var music_fade_out_duration: float = 2.0


# -------------------------
# CAMERA MOVEMENT SETTINGS
# -------------------------

@export_group("Camera Movement")
@export var stand_up_duration: float = 1.5
@export var turn_duration: float = 1.5
@export var walking_duration: float = 4.0
@export var lie_down_duration: float = 2.0
@export var fade_to_black_duration: float = 1.5


# -------------------------
# CAMERA AND MARKERS
# -------------------------

@onready var camera: Camera3D = $CameraRig/Camera3D

@onready var seated_marker: Marker3D = $CameraMarkers/SeatedPosition
@onready var stand_up_marker: Marker3D = $CameraMarkers/StandUp
@onready var bed_look_marker: Marker3D = $CameraMarkers/BedLookPosition

@onready var step_markers: Array[Marker3D] = [
	$CameraMarkers/StepPosition1,
	$CameraMarkers/StepPosition2,
	$CameraMarkers/StepPosition3,
	$CameraMarkers/StepPosition4
]

@onready var approach_marker: Marker3D = $CameraMarkers/BedApproachPosition
@onready var lying_marker: Marker3D = $CameraMarkers/LyingPosition


# -------------------------
# UI, AUDIO AND LIGHTING
# -------------------------

@onready var music: AudioStreamPlayer = $Music
@onready var take_nap_button: Button = $CanvasLayer/MenuPanel/TakeNapButton
@onready var fade_overlay: ColorRect = $CanvasLayer/FadeOverlay
@onready var main_light: OmniLight3D = $Lighting/MainLight


# -------------------------
# VARIABLES
# -------------------------

var sequence_started: bool = false
var camera_start_transform: Transform3D


# -------------------------
# READY
# -------------------------

func _ready() -> void:
	# Position the camera at the seated starting marker.
	camera.global_transform = seated_marker.global_transform

	# Set initial kitchen lighting.
	main_light.light_energy = 0.18

	# Initialize screen fade.
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Hide corner character until the player lies down.
	corner_boi.hide()

	# Start music quietly and fade in.
	music.volume_db = -60.0
	music.play()

	var music_tween: Tween = create_tween()
	music_tween.tween_property(
		music,
		"volume_db",
		music_target_volume_db,
		music_fade_in_duration
	)

	# Connect the Take a Nap button.
	take_nap_button.pressed.connect(start_nap_sequence)


# -------------------------
# NAP SEQUENCE
# -------------------------

func start_nap_sequence() -> void:
	if sequence_started:
		return

	sequence_started = true
	take_nap_button.hide()

	print("KITCHEN: Nap sequence started")

	# STEP 1: Stand up from the chair.
	await move_camera_to(stand_up_marker, stand_up_duration)

	# STEP 2: Turn toward the bed.
	await move_camera_to(bed_look_marker, turn_duration)

	# STEP 3: Walk through all four step markers.
	await walk_to_bed()

	# STEP 4: Lie down on the bed.
	corner_boi.show()
	await move_camera_to(lying_marker, lie_down_duration)

	# STEP 5: Fade out music and picture.
	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)

	fade_tween.tween_property(
		music,
		"volume_db",
		-60.0,
		music_fade_out_duration
	)

	fade_tween.tween_property(
		fade_overlay,
		"modulate:a",
		1.0,
		fade_to_black_duration
	)

	await fade_tween.finished

	music.stop()

	print("KITCHEN: Transition complete")

	# Hospital scene transition goes here later.


# -------------------------
# SMOOTH CINEMATIC CAMERA MOVEMENT
# -------------------------

func move_camera_to(target: Marker3D, duration: float) -> void:
	camera_start_transform = camera.global_transform

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		interpolate_camera.bind(target.global_transform),
		0.0,
		1.0,
		duration
	)

	await tween.finished


func interpolate_camera(weight: float, target_transform: Transform3D) -> void:
	camera.global_transform = camera_start_transform.interpolate_with(
		target_transform,
		weight
	)


# -------------------------
# CONTINUOUS WALK TO BED
# -------------------------

func walk_to_bed() -> void:
	# Combine the four walking markers with the final approach.
	var walking_path: Array[Marker3D] = step_markers.duplicate()
	walking_path.append(approach_marker)

	# Divide the total walking time between all destinations.
	var segment_duration: float = walking_duration / walking_path.size()

	var walk_tween: Tween = create_tween()
	walk_tween.set_trans(Tween.TRANS_LINEAR)

	# Travel through each marker without stopping.
	for marker in walking_path:
		walk_tween.tween_property(
			camera,
			"global_transform",
			marker.global_transform,
			segment_duration
		)

	await walk_tween.finished
