extends Area3D

@export var bounce_strength: float = 40.0


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.velocity.y = bounce_strength
