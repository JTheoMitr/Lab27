
extends AnimatedSprite2D

var playing_forward: bool = true


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	if playing_forward:
		playing_forward = false
		play_backwards()
	else:
		playing_forward = true
		play()
