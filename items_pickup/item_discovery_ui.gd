
class_name ItemDiscoveryUI
extends CanvasLayer

signal presentation_finished

@export_group("Model Animation")
@export var reveal_duration: float = 0.75
@export var rotation_speed: float = 0.85

@onready var item_stage: VBoxContainer = $Screen/CenterContainer/Panel/Content/ItemStage
@onready var instruction_stage: VBoxContainer = $Screen/CenterContainer/Panel/Content/InstructionStage

@onready var model_pivot: Node3D = $Screen/CenterContainer/Panel/Content/ViewerFrame/ViewerContent/ModelViewport/SubViewport/PreviewWorld/ModelPivot
@onready var model_viewport: SubViewportContainer = $Screen/CenterContainer/Panel/Content/ViewerFrame/ViewerContent/ModelViewport

@onready var tutorial_video: AnimatedSprite2D = $Screen/CenterContainer/Panel/Content/ViewerFrame/ViewerContent/TutorialVideo

@onready var item_title: Label = $Screen/CenterContainer/Panel/Content/ItemStage/ItemTitle
@onready var item_description: Label = $Screen/CenterContainer/Panel/Content/ItemStage/ItemDescription

@onready var instruction_title: Label = $Screen/CenterContainer/Panel/Content/InstructionStage/InstructionTitle
@onready var instruction_body: Label = $Screen/CenterContainer/Panel/Content/InstructionStage/InstructionBody

@onready var continue_button: Button = $Screen/CenterContainer/Panel/Content/ContinueButton

var preview_model: Node3D = null

var is_open: bool = false
var is_rotating: bool = false
var showing_instructions: bool = false
var has_instructions: bool = false
var has_tutorial_animation: bool = false

var previous_mouse_mode: Input.MouseMode

var reveal_tween: Tween


func _ready() -> void:
	hide()
	set_process(false)

	tutorial_video.stop()
	tutorial_video.hide()
	model_viewport.show()

	continue_button.pressed.connect(_on_continue_pressed)


func _process(delta: float) -> void:
	if is_rotating:
		model_pivot.rotate_y(rotation_speed * delta)


# -------------------------
# SHOW ITEM DISCOVERY
# -------------------------

func show_item(
	model_scene: PackedScene,
	title: String,
	description: String,
	controls_title: String = "",
	controls_description: String = "",
	model_scale: float = 1.0,
	model_offset: Vector3 = Vector3.ZERO,
	tutorial_frames: SpriteFrames = null,
	tutorial_animation: StringName = &"default"
) -> void:
	if is_open:
		return

	is_open = true
	showing_instructions = false
	has_instructions = not controls_title.is_empty() or not controls_description.is_empty()

	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# -------------------------
	# SET ITEM INFORMATION
	# -------------------------

	item_title.text = title
	item_description.text = description

	instruction_title.text = controls_title
	instruction_body.text = controls_description

	item_stage.show()
	instruction_stage.hide()

	continue_button.text = "CONTINUE" if has_instructions else "CLOSE"

	# -------------------------
	# RESET TUTORIAL VIEWER
	# -------------------------

	tutorial_video.stop()
	tutorial_video.hide()

	model_viewport.show()

	tutorial_video.sprite_frames = tutorial_frames

	has_tutorial_animation = false

	if tutorial_frames != null:
		if tutorial_frames.has_animation(tutorial_animation):
			tutorial_video.animation = tutorial_animation

			has_tutorial_animation = true
		else:
			push_warning(
				"Item Discovery: Tutorial animation not found: "
				+ str(tutorial_animation)
			)

	# -------------------------
	# REMOVE PREVIOUS MODEL
	# -------------------------

	if reveal_tween != null:
		reveal_tween.kill()
		reveal_tween = null

	for child in model_pivot.get_children():
		model_pivot.remove_child(child)
		child.queue_free()

	preview_model = null

	# -------------------------
	# SPAWN PREVIEW MODEL
	# -------------------------

	if model_scene != null:
		var instance: Node = model_scene.instantiate()

		if instance is Node3D:
			preview_model = instance as Node3D

			model_pivot.add_child(preview_model)

			preview_model.position = model_offset
			preview_model.scale = Vector3.ONE * model_scale
		else:
			push_warning(
				"Item Discovery: Preview scene root must be Node3D."
			)

			instance.queue_free()

	# -------------------------
	# PREPARE MODEL REVEAL
	# -------------------------

	is_rotating = false

	model_pivot.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	model_pivot.scale = Vector3.ONE * 0.65
	model_pivot.position = Vector3(0.0, -0.25, 0.0)

	show()
	set_process(true)

	# -------------------------
	# SPIN AND RISE ANIMATION
	# -------------------------

	reveal_tween = create_tween()

	reveal_tween.set_parallel(true)
	reveal_tween.set_trans(Tween.TRANS_SINE)
	reveal_tween.set_ease(Tween.EASE_OUT)

	reveal_tween.tween_property(
		model_pivot,
		"rotation_degrees:y",
		0.0,
		reveal_duration
	)

	reveal_tween.tween_property(
		model_pivot,
		"scale",
		Vector3.ONE,
		reveal_duration
	)

	reveal_tween.tween_property(
		model_pivot,
		"position:y",
		0.0,
		reveal_duration
	)

	await reveal_tween.finished

	if is_open and not showing_instructions:
		is_rotating = true


# -------------------------
# CONTINUE BUTTON
# -------------------------

func _on_continue_pressed() -> void:
	if not is_open:
		return

	if has_instructions and not showing_instructions:
		show_instruction_page()
	else:
		close_presentation()


# -------------------------
# SHOW INSTRUCTIONS
# -------------------------

func show_instruction_page() -> void:
	showing_instructions = true
	is_rotating = false

	if reveal_tween != null:
		reveal_tween.kill()
		reveal_tween = null

	item_stage.hide()
	instruction_stage.show()

	continue_button.text = "CLOSE"

	# -------------------------
	# SWITCH MODEL TO ANIMATION
	# -------------------------

	if has_tutorial_animation:
		model_viewport.hide()

		tutorial_video.show()
		tutorial_video.frame = 0
		tutorial_video.play()
	else:
		# No tutorial animation assigned.
		# Keep the 3D model visible.
		tutorial_video.stop()
		tutorial_video.hide()

		model_viewport.show()
		is_rotating = true


# -------------------------
# CLOSE DISCOVERY POPUP
# -------------------------

func close_presentation() -> void:
	if not is_open:
		return

	is_open = false
	is_rotating = false
	showing_instructions = false

	if reveal_tween != null:
		reveal_tween.kill()
		reveal_tween = null

	tutorial_video.stop()
	tutorial_video.hide()

	model_viewport.show()

	set_process(false)
	hide()

	Input.mouse_mode = previous_mouse_mode

	presentation_finished.emit()
