
extends Node3D

@export_group("Flight")
@export var speed: float = 22.0
@export var max_flight_time: float = 5.0
@export_flags_3d_physics var collision_mask: int = 3

@export_group("Burning")
@export var burn_duration: float = 8.0

@onready var impact_sparks: GPUParticles3D = $ImpactSparks
@onready var flare_hiss: AudioStreamPlayer3D = $FlareHiss


var direction: Vector3 = Vector3.FORWARD
var shooter: CollisionObject3D
var flying: bool = false
var flight_time: float = 0.0
var burning: bool = false


func _ready() -> void:
	# No sparks until the flare hits something.
	impact_sparks.emitting = false


func launch(
	start_position: Vector3,
	launch_direction: Vector3,
	source: CollisionObject3D
) -> void:
	global_position = start_position
	direction = launch_direction.normalized()
	shooter = source
	flying = true


func _physics_process(delta: float) -> void:
	if not flying:
		return

	flight_time += delta

	if flight_time >= max_flight_time:
		start_burning()
		return

	var next_position: Vector3 = global_position + direction * speed * delta

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position,
		next_position,
		collision_mask
	)

	if is_instance_valid(shooter):
		query.exclude = [shooter.get_rid()]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if not hit.is_empty():
		global_position = hit["position"]
		start_burning()

		print("Flare hit: ", hit["collider"].name)
		return

	global_position = next_position


func start_burning() -> void:
	if burning:
		return

	burning = true
	flying = false
	flare_hiss.play()

	print("Flare burning at: ", global_position)

	# Start the sparks only after impact.
	impact_sparks.restart()
	impact_sparks.emitting = true

	await get_tree().create_timer(burn_duration).timeout

	# Stop emitting before removing the flare.
	impact_sparks.emitting = false

	queue_free()
