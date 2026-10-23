
extends Control

signal hack_charge_complete

@export_group("Appearance")
@export var reticle_size: float = 24.0
@export var corner_length: float = 9.0
@export var line_width: float = 2.0
@export var pulse_speed: float = 2.5
@export var pulse_amount: float = 0.12
@export var charge_rotation_speed: float = 3.0

@export var idle_color: Color = Color("#4dbbff")
@export var target_color: Color = Color("#ff5252")

@export_group("Charging")
@export var charge_duration: float = 1.5

var targeting: bool = false
var charging: bool = false
var charge_progress: float = 0.0
var charge_rotation: float = 0.0

var animation_time: float = 0.0
var charge_finished: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(delta: float) -> void:
	animation_time += delta
	
	if charging and targeting:
		charge_rotation += charge_rotation_speed * delta
	else:
		charge_rotation = lerp_angle(charge_rotation, 0.0, minf(delta * 10.0, 1.0))

	if charging and targeting and not charge_finished:
		charge_progress += delta / maxf(charge_duration, 0.01)
		charge_progress = clampf(charge_progress, 0.0, 1.0)

		if charge_progress >= 1.0:
			charge_finished = true
			charging = false
			hack_charge_complete.emit()

	queue_redraw()


func set_targeting(value: bool) -> void:
	if targeting == value:
		return

	targeting = value

	if not targeting:
		cancel_charge()


func start_charge() -> void:
	if not targeting or charge_finished:
		return

	charging = true


func cancel_charge() -> void:
	charging = false
	charge_progress = 0.0
	charge_finished = false


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_set_transform(center, charge_rotation)

	var pulse: float = sin(animation_time * pulse_speed)
	var scale_factor: float = 1.0 + pulse * pulse_amount

	var half_size: float = reticle_size * scale_factor

	var color: Color = target_color if targeting else idle_color
	color.a = 0.8 + 0.2 * (pulse * 0.5 + 0.5)

	var x: float = half_size
	var y: float = half_size
	var c: float = corner_length
	

	# Translucent square fill
	var fill_color: Color = color
	fill_color.a = 0.15

	draw_rect(
		Rect2(
			Vector2(-x, -y),
			Vector2(x * 2.0, y * 2.0)
		),
		fill_color,
		true
	)

	# Top left
	draw_line(Vector2(-x, -y), Vector2(-x + c, -y), color, line_width, true)
	draw_line(Vector2(-x, -y), Vector2(-x, -y + c), color, line_width, true)

	# Top right
	draw_line(Vector2(x, -y), Vector2(x - c, -y), color, line_width, true)
	draw_line(Vector2(x, -y), Vector2(x, -y + c), color, line_width, true)

	# Bottom left
	draw_line(Vector2(-x, y), Vector2(-x + c, y), color, line_width, true)
	draw_line(Vector2(-x, y), Vector2(-x, y - c), color, line_width, true)

	# Bottom right
	draw_line(Vector2(x, y), Vector2(x - c, y), color, line_width, true)
	draw_line(Vector2(x, y), Vector2(x, y - c), color, line_width, true)

	# Center dot
	draw_circle(Vector2.ZERO, 2.0, color, true, -1.0, true)

	# Reset transform before drawing the charging meter
	draw_set_transform(Vector2.ZERO, 0.0)

	# Charging meter
	if charging or charge_progress > 0.0:
		var radius: float = half_size + 11.0

		draw_arc(
			center,
			radius,
			0.0,
			TAU,
			48,
			Color(color.r, color.g, color.b, 0.2),
			3.0,
			true
		)

		draw_arc(
			center,
			radius,
			-PI / 2.0,
			-PI / 2.0 + TAU * charge_progress,
			48,
			color,
			3.0,
			true
		)
