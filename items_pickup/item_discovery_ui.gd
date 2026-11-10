
class_name ItemDiscoveryUI
extends CanvasLayer

signal presentation_finished

@export_group("Model Animation")
@export var reveal_duration: float = 0.65
@export var rotation_speed: float = 0.55

@onready var item_stage: VBoxContainer = $Screen/CenterContainer/Panel/Content/ItemStage
@onready var instruction_stage: VBoxContainer = $Screen/CenterContainer/Panel/Content/InstructionStage

@onready var model_pivot: Node3D = $Screen/CenterContainer/Panel/Content/ItemStage/ModelViewport/SubViewport/PreviewWorld/ModelPivot

@onready var item_title: Label = $Screen/CenterContainer/Panel/Content/ItemStage/ItemTitle
@onready var item_description: Label = $Screen/CenterContainer/Panel/Content/ItemStage/ItemDescription

@onready var instruction_title: Label = $Screen/CenterContainer/Panel/Content/InstructionStage/InstructionTitle
@onready var instruction_body: Label = $Screen/CenterContainer/Panel/Content/InstructionStage/InstructionBody

@onready var continue_button: Button = $Screen/CenterContainer/Panel/Content/ContinueButton

var preview_model: Node3D
var is_open: bool = false
var is_rotating: bool = false
var showing_instructions: bool = false
var has_instructions: bool = false

var previous_mouse_mode: Input.MouseMode


func _ready() -> void:
	hide()
	set_process(false)

	continue_button.pressed.connect(_on_continue_pressed)


func _process(delta: float) -> void:
	if is_rotating:
		model_pivot.rotate_y(rotation_speed * delta)


func show_item(
	model_scene: PackedScene,
	title: String,
	description: String,
	controls_title: String = "",
	controls_description: String = "",
	model_scale: float = 1.0,
	model_offset: Vector3 = Vector3.ZERO
) -> void:
	if is_open:
		return

	is_open = true
	showing_instructions = false
	has_instructions = not controls_description.is_empty()

	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	item_title.text = title
	item_description.text = description

	instruction_title.text = controls_title
	instruction_body.text = controls_description

	item_stage.show()
	instruction_stage.hide()
	continue_button.text = "CONTINUE"

	# Remove any previous preview model.
	for child in model_pivot.get_children():
		child.queue_free()

	preview_model = null

	# Spawn the visual-only model.
	if model_scene != null:
		preview_model = model_scene.instantiate() as Node3D

		if preview_model != null:
			model_pivot.add_child(preview_model)
			preview_model.position = model_offset
			preview_model.scale = Vector3.ONE * model_scale

	# Prepare the reveal animation.
	is_rotating = false
	model_pivot.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	model_pivot.scale = Vector3.ONE * 0.65
	model_pivot.position.y = -0.25

	show()
	set_process(true)

	# Spin and rise into the center of the viewer.
	var reveal_tween: Tween = create_tween()
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


func _on_continue_pressed() -> void:
	if not is_open:
		return

	if has_instructions and not showing_instructions:
		show_instruction_page()
	else:
		close_presentation()


func show_instruction_page() -> void:
	showing_instructions = true
	is_rotating = false

	item_stage.hide()
	instruction_stage.show()

	continue_button.text = "CLOSE"


func close_presentation() -> void:
	is_open = false
	is_rotating = false

	set_process(false)
	hide()

	Input.mouse_mode = previous_mouse_mode

	presentation_finished.emit()
