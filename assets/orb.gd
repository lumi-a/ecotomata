extends RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start some random angular upwards velocity
	set_axis_velocity(Vector2.from_angle(randf_range(5.0 / 8.0 * TAU, 7.0 / 8.0 * TAU)) * 200)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Move towards (0, 0)
	var difference = Vector2(0, 0) - position
	var normalized = difference.normalized()
	apply_force(normalized * 2000)
	if position.x < 0 or position.y < 0:
		print("orbbbb")
		queue_free()
	pass