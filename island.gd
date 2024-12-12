extends Node3D

@export var camera_rotation_node: Node3D
var camera: Camera3D
@export var ui_node: Control

const num_initial_sapling_attempts: int = 0
const num_initial_plant_attempts: int = 0
const min_neighbor_distance: float = 0.2
const max_neighbor_distance: float = 1.5
const max_raycast_distance: float = 50.0

var space_state: PhysicsDirectSpaceState3D
var aabb = $rock_largeE.get_aabb()
var all_trees = preload("res://assets/trees/all.tscn").instantiate()
var all_plants = preload("res://assets/plants/all.tscn").instantiate()
var fire = preload("res://assets/fire.tscn").instantiate()
var lightning_instance = preload("res://assets/lightning.tscn").instantiate()
var orb_instance = preload("res://assets/orb.tscn").instantiate()

var polygon_points: PackedVector2Array

var trees: Array = []
var neighbor_graph: Dictionary = {} # Undirected, unweighted

enum TreeState {
	Growing,
	Static,
	StartedBurning,
	BurningDown,
	Embers,
}
var tree_states: Dictionary = {}
var tree_timers: Dictionary = {}
var tree_orb_timers: Dictionary = {}
var tree_fires: Dictionary = {}
const grow_time = 0.5
const started_burning_time = 0.25
const burning_down_time = 0.5
const ember_time = 1.0

var flower_attempts = 0 # How many flowers should be bought in the next couple frames
var max_flowers_per_frame = 10 # At most how many flowers to try adding per frame

func remove_all_but_one(variant: Variant):
	var children = variant.get_children()
	var chosen = randi() % children.size()
	for i in children.size():
		if i != chosen:
			children[i].queue_free()

func try_adding_tree():
	var random_point = aabb.position + Vector3(randf_range(-20, 20) * aabb.size.x, 0, randf_range(-20, 20) * aabb.size.z)
	var query = PhysicsRayQueryParameters3D.create(random_point + Vector3.UP * max_raycast_distance, random_point - Vector3.UP * max_raycast_distance)
	var result = space_state.intersect_ray(query)
	
	if not result or result.position.y < 0.2:
		return false
		 
	# Search neighbors, or terminate early if a neighbor is too close
	var neighbors = []

	for other_tree in trees:
		var distance = other_tree.position.distance_to(result.position)
		if distance < min_neighbor_distance:
			return false
		elif distance < max_neighbor_distance:
			neighbors.append(other_tree)

	var tree = all_trees.duplicate()
	remove_all_but_one(tree)
	add_child(tree)
	tree.position = result.position - position
	tree.rotate_y(randf_range(0, PI * 2))
	# Align tree with surface normal
	if result.normal != Vector3.UP:
		var up = result.normal
		var axis = Vector3.UP.cross(up).normalized()
		var angle = Vector3.UP.angle_to(up)
		tree.rotate(axis, angle / 2)
	
	# Add to neighbor graph
	var id = tree.get_instance_id()
	neighbor_graph[id] = []
	for neighbor in neighbors:
		var neighbor_id = neighbor.get_instance_id()
		neighbor_graph[id].append(neighbor)
		neighbor_graph[neighbor_id].append(tree)
	trees.append(tree)

	# set attributes
	tree_states[id] = TreeState.Growing
	tree_timers[id] = 0.0
	tree.scale = Vector3.ZERO
	
	return true

func buy_flowers():
	flower_attempts += 250

func try_adding_flower():
	var random_point = aabb.position + Vector3(randf_range(-20, 20) * aabb.size.x, 0, randf_range(-20, 20) * aabb.size.z)
	var query = PhysicsRayQueryParameters3D.create(random_point + Vector3.UP * max_raycast_distance, random_point - Vector3.UP * max_raycast_distance)
	var result = space_state.intersect_ray(query)
	if result and result.position.y > 0.2:
		var plant = all_plants.duplicate()
		remove_all_but_one(plant)
		add_child(plant)
		plant.position = result.position - position
		plant.rotate_y(randf_range(0, PI * 2))
		if result.normal != Vector3.UP:
			var up = result.normal
			var axis = Vector3.UP.cross(up).normalized()
			var angle = Vector3.UP.angle_to(up)
			plant.rotate(axis, angle)

func _ready():
	space_state = get_world_3d().direct_space_state
	camera = camera_rotation_node.get_node("camera")
	ui_node.bought_flowers.connect(buy_flowers)

	# Spawn trees		
	for _attempts in num_initial_sapling_attempts:
		try_adding_tree()

func poisson(λ:float):
	# https://en.wikipedia.org/wiki/Poisson_distribution#Computational_methods
	var x = 0
	var p = exp(-λ)
	var s = p
	var u = randf()
	while u > s:
		x += 1
		p *= λ / x
		s += p
	return x

func light_up_tree(tree) -> bool:
	var id = tree.get_instance_id()
	if tree_states[id] == TreeState.Static:
		tree_states[id] = TreeState.StartedBurning
		tree_timers[id] = 0.0

		# 🔥 👌
		var fire_instance = fire.duplicate()
		tree_fires[id] = fire_instance
		tree.add_child(fire_instance)
		return true
	return false

func add_orb():
	ui_node.orbs += 1

func _process(delta):
	var expected_lightnings_per_second: float = (ui_node.flower_max_level - ui_node.flower_level) / ui_node.flower_max_level
	var expected_saplings_per_second: float = 50.0 * (ui_node.tree_level + 3) / (ui_node.tree_max_level + 3)

	# try adding flowers
	var flower_attempts_this_frame = 0
	while flower_attempts_this_frame < max_flowers_per_frame and flower_attempts > 0:
		flower_attempts_this_frame += 1
		flower_attempts -= 1
		try_adding_flower()

	var num_lightnings = poisson(expected_lightnings_per_second * delta)
	# I guess it makes sense for every lightning to hit a tree?
	# Whatev
	if trees.size() > 0:
		for _i in num_lightnings:
			var hit_tree = trees[randi() % trees.size()]
			if light_up_tree(hit_tree):
				# Thundr
				var new_lightning = lightning_instance.duplicate()
				new_lightning.position = hit_tree.position
				new_lightning.rotation.y = camera_rotation_node.rotation.y
				add_child(new_lightning)
	
	var num_saplings = poisson(expected_saplings_per_second * delta)
	for _i in num_saplings:
		try_adding_tree()

	var tree_ix = 0
	while tree_ix < trees.size():
		var tree = trees[tree_ix]
		var id = tree.get_instance_id()
		match tree_states[id]:
			TreeState.Static:
				tree_orb_timers[id] += delta
				if tree_orb_timers[id] >= 1.0:
					tree_orb_timers[id] -= 1.0
					var orb = orb_instance.duplicate()
					orb.position = camera.unproject_position(tree.position + Vector3.UP * 0.875)
					orb.tree_exited.connect(add_orb)
					add_child(orb)

			TreeState.Growing:
				tree_timers[id] += delta
				tree.scale = lerp(Vector3.ZERO, Vector3.ONE, tree_timers[id] / grow_time)
				if tree_timers[id] >= grow_time:
					tree.scale = Vector3.ONE
					tree_states[id] = TreeState.Static
					tree_orb_timers[id] = 0
			
			TreeState.StartedBurning:
				tree_timers[id] += delta
				if tree_timers[id] >= started_burning_time:
					tree_states[id] = TreeState.BurningDown
					tree_timers[id] = 0.0

					# Set static neighbors ablaze
					for neighbor in neighbor_graph[id]:
						light_up_tree(neighbor)

			TreeState.BurningDown:
				tree_timers[id] += delta
				tree.scale = lerp(Vector3.ONE, Vector3.ZERO, tree_timers[id] / burning_down_time)
				if tree_timers[id] >= burning_down_time:
					for child in tree_fires[id].get_children():
						# If particle-generator, stop emission:
						if child is GPUParticles3D:
							child.emitting = false

					tree_states[id] = TreeState.Embers
					tree_timers[id] = 0.0
			
			TreeState.Embers:
				tree_timers[id] += delta
				if tree_timers[id] >= ember_time:
					trees.remove_at(tree_ix)
					tree_ix -= 1
					var old_neighbors = neighbor_graph[id]
					for neighbor in old_neighbors:
						neighbor_graph[neighbor.get_instance_id()].erase(tree)
					neighbor_graph.erase(id)
					
					tree_fires[id].queue_free()
					tree_fires.erase(id)
					tree_states.erase(id)
					tree_timers.erase(id)
					tree_orb_timers.erase(id)
					tree.queue_free()
		tree_ix += 1
