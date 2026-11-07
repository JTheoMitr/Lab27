
extends OmniLight3D

@export_group("Flicker")

@export var normal_energy: float = 1.0
@export var dim_energy: float = 0.12
@export var min_time_between_flickers: float = 2.0
@export var max_time_between_flickers: float = 6.0
@export var flicker_duration: float = 0.06
@export var flicker_chance: float = 0.75

var flicker_timer: float = 0.0
var flicker_remaining: float = 0.0
var is_flickering: bool = false


func _ready() -> void:
	light_energy = normal_energy
	schedule_next_flicker()



func _process(delta: float) -> void:
	if is_flickering:
		
		flicker_remaining -= delta

		if flicker_remaining <= 0.0:
			is_flickering = false
	
			light_energy = normal_energy
			schedule_next_flicker()

		return

	flicker_timer -= delta

	if flicker_timer <= 0.0:
		if randf() <= flicker_chance:
			is_flickering = true

			flicker_remaining = flicker_duration
			light_energy = dim_energy
		else:
			schedule_next_flicker()
			


func schedule_next_flicker() -> void:
	flicker_timer = randf_range(
		min_time_between_flickers,
		max_time_between_flickers
	)
