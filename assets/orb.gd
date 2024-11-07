extends RigidBody2D

func _ready() -> void:
	set_axis_velocity(Vector2.from_angle(randf_range(5.0 / 8.0 * TAU, 7.0 / 8.0 * TAU)) * 200)

func _physics_process(_delta: float) -> void:
	# Move towards (0, 0)
	var difference = Vector2(0, 0) - position
	var normalized = difference.normalized()
	apply_force(normalized * 2000)
	if position.x < 0 or position.y < 0:
		queue_free()