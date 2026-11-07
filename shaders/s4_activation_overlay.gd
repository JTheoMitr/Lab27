
class_name S4ActivationOverlay
extends CanvasLayer

signal activation_finished

@export_group("Activation Timing")
@export var first_glitch_duration: float = 0.25
@export var second_glitch_duration: float = 0.45
@export var text_fade_duration: float = 0.25
@export var text_hold_duration: float = 1.2
@export var fade_out_duration: float = 0.5


@export_group("Responsive UI")
@export var reference_height: float = 720.0
@export var base_panel_size: Vector2 = Vector2(700.0, 420.0)
@onready var center_container: CenterContainer = $CenterContainer



@export_group("Boot Display Glitch")
@export var boot_glitch_min: float = 0.18
@export var boot_glitch_max: float = 0.35
@export var boot_glitch_cycle: float = 0.45

var boot_glitch_tween: Tween


@export_group("Implant Flash")
@export var red_flash_duration: float = 0.12
@export var red_flash_intensity: float = 0.75

@onready var glitch_rect: ColorRect = $GlitchRect
@onready var red_flash: ColorRect = $RedFlash
@onready var activation_text: RichTextLabel = $CenterContainer/ActivationText
@onready var typing_beep: AudioStreamPlayer = $TypingBeep
@onready var glitch_audio: AudioStreamPlayer = $GlitchAudioPlayer
@onready var black_rect: ColorRect = $BlackRect

@export_group("Typewriter Effect")
@export var typing_character_delay: float = 0.025
@export_range(1, 20, 1) var beep_every_characters: int = 20

var glitch_material: ShaderMaterial
var is_activating: bool = false
var red_flash_tween: Tween


func _ready() -> void:
	glitch_material = glitch_rect.material as ShaderMaterial

	if glitch_material == null:
		push_error("S4 Overlay: GlitchRect needs a ShaderMaterial.")
		return

	glitch_material = glitch_material.duplicate() as ShaderMaterial
	glitch_rect.material = glitch_material
	
	glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activation_text.mouse_filter = Control.MOUSE_FILTER_IGNORE

	red_flash.color = Color("#D91F28")
	red_flash.modulate.a = 0.0

	activation_text.bbcode_enabled = true
	activation_text.scroll_active = false
	activation_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	activation_text.modulate.a = 0.0

	
	update_boot_text_scale()
	get_viewport().size_changed.connect(update_boot_text_scale)


	set_glitch_intensity(0.0)
	hide()


# -------------------------
# RED IMPLANT FLASH
# -------------------------

func play_implant_flash() -> void:
	if red_flash_tween != null and red_flash_tween.is_running():
		red_flash_tween.kill()

	show()
	glitch_audio.play()
	red_flash.modulate.a = 0.0

	red_flash_tween = create_tween()

	# Immediate, harsh red flash.
	red_flash_tween.tween_property(
		red_flash,
		"modulate:a",
		red_flash_intensity,
		0.025
	)

	# Rapidly fade back to normal.
	red_flash_tween.tween_property(
		red_flash,
		"modulate:a",
		0.0,
		red_flash_duration
	)

	await red_flash_tween.finished

	if not is_activating:
		hide()


# -------------------------
# MAIN ACTIVATION
# -------------------------

func play_activation() -> void:
	if is_activating or glitch_material == null:
		return

	is_activating = true
	black_rect.show()
	show()

	activation_text.modulate.a = 0.0
	red_flash.modulate.a = 0.0
	set_glitch_intensity(0.0)

	print("S4-MYND: Neural interface booting.")

	# First violent signal interruption.
	await animate_glitch(0.0, 1.0, first_glitch_duration)

	# Brief signal dropout.
	await animate_glitch(1.0, 0.25, 0.12)

	# Second sustained glitch.
	await animate_glitch(0.25, 0.85, second_glitch_duration)

	
	# Stabilize just enough for the boot message to be readable.
	await animate_glitch(0.85, boot_glitch_min, 0.3)

	# Keep low-level interference active during the boot message.
	start_boot_glitch()


	# Type the boot display while the glitch continues.
	activation_text.modulate.a = 1.0
	activation_text.visible_characters = 0

	await type_activation_text()

	print("S4-MYND: SYSTEM ONLINE")

	# Let the player read the completed message.
	await get_tree().create_timer(text_hold_duration).timeout


	
	# Stop the repeating glitch before the final fade.
	stop_boot_glitch()

	# Clear the message and interference together.
	var final_tween: Tween = create_tween()
	final_tween.set_parallel(true)


	final_tween.tween_property(
		activation_text,
		"modulate:a",
		0.0,
		fade_out_duration
	)

	
	final_tween.tween_method(
		set_glitch_intensity,
		float(glitch_material.get_shader_parameter("intensity")),
		0.0,
		fade_out_duration
	)


	await final_tween.finished

	hide()
	black_rect.hide()
	is_activating = false

	activation_finished.emit()


# -------------------------
# GLITCH HELPERS
# -------------------------

func animate_glitch(from: float, to: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)

	tween.tween_method(
		set_glitch_intensity,
		from,
		to,
		duration
	)

	await tween.finished


func set_glitch_intensity(value: float) -> void:
	if glitch_material != null:
		glitch_material.set_shader_parameter(
			"intensity",
			value
		)
		

func start_boot_glitch() -> void:
	if boot_glitch_tween != null:
		boot_glitch_tween.kill()

	boot_glitch_tween = create_tween()
	boot_glitch_tween.set_loops()

	boot_glitch_tween.tween_method(
		set_glitch_intensity,
		boot_glitch_min,
		boot_glitch_max,
		boot_glitch_cycle
	)

	boot_glitch_tween.tween_method(
		set_glitch_intensity,
		boot_glitch_max,
		boot_glitch_min,
		boot_glitch_cycle
	)


func stop_boot_glitch() -> void:
	if boot_glitch_tween != null:
		boot_glitch_tween.kill()
		boot_glitch_tween = null


func type_activation_text() -> void:
	activation_text.visible_characters = 0

	var total_characters: int = activation_text.get_total_character_count()

	for i in range(1, total_characters + 1):
		activation_text.visible_characters = i

		# Play a short electronic beep periodically.
		if i % beep_every_characters == 0:
			if typing_beep.stream != null:
				typing_beep.play()

		await get_tree().create_timer(typing_character_delay).timeout

	if typing_beep.playing:
		typing_beep.stop()

	print("S4-MYND: Boot text completed.")



func update_boot_text_scale() -> void:
	var viewport_height: float = get_viewport().get_visible_rect().size.y
	var scale_factor: float = viewport_height / reference_height

	var header_size: int = maxi(1, roundi(23.0 * scale_factor))
	var body_size: int = maxi(1, roundi(20.0 * scale_factor))
	var title_size: int = maxi(1, roundi(42.0 * scale_factor))
	var footer_size: int = maxi(1, roundi(22.0 * scale_factor))


	activation_text.custom_minimum_size = base_panel_size * scale_factor

	var previous_visible: int = activation_text.visible_characters

	activation_text.text = """
[center][color=#78DCD6][font_size=%d]S4-MYND / NEURAL INTERFACE[/font_size][/color]

[color=#B7DCD9][font_size=%d]BIOMETRIC LINK ........ ESTABLISHED
NEURAL SYNCHRONIZATION . COMPLETE
SIGNAL INTEGRITY ...... 100%%[/font_size][/color]

[color=#82FFF0][font_size=%d][b][pulse freq=2.5 color=#00FFFFFF ease=-2.0]SYSTEM ONLINE[/pulse][/b][/font_size][/color]

[color=#78DCD6][font_size=%d]HACKING MODULE ENABLED[/font_size][/color][/center]
""" % [header_size, body_size, title_size, footer_size]

	activation_text.visible_characters = previous_visible
