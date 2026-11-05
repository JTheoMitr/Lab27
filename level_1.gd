extends Node3D

@onready var level_ambience_1 = $AudioStreamPlayer

func _ready() -> void:
	#print("LEVEL 1: Ready completed!")
	level_ambience_1.play()
	


func _on_audio_stream_player_finished() -> void:
	level_ambience_1.play()
