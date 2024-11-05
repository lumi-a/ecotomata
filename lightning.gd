extends Node3D


var fadeout_time = 0.5
var fadeout_timer: float = 0.5

func _ready() -> void:
	# flip sprite sometimes
	$Sprite3D.flip_h = randf() > 0.5

func _process(delta: float) -> void:
	fadeout_timer -= delta
	if fadeout_timer < 0:
		queue_free()
	else:
		$Sprite3D.modulate.a = fadeout_timer / fadeout_time
