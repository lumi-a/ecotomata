extends Node2D

# @onready var body: AnimatableBody2D = $AnimatableBody2D
@onready var body: RigidBody2D = $RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start some random angular upwards velocity
	body.set_axis_velocity(Vector2.from_angle(randf_range(5 / 8 * TAU, 7 / 8 * TAU)) * 200)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Move towards (0, 0)
	var difference = Vector2(0, 0) - position
	var normalized = difference.normalized()
	body.apply_force(normalized * 2000)
	pass
