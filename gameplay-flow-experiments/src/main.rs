use rand::prelude::*;

/// Success-constant derived experimentally, probability
/// that Godot's `try_adding_tree` successfully grows a tree.
/// ```gd
/// var attempts = 1000000
/// var successes = 0
/// for _i in attempts:
/// 	var random_point = aabb.position + Vector3(randf_range(-20, 20) * aabb.size.x, 0, randf_range(-20, 20) * aabb.size.z)
/// 	var query = PhysicsRayQueryParameters3D.create(random_point + Vector3.UP * max_raycast_distance, random_point - Vector3.UP * max_raycast_distance)
/// 	var result = space_state.intersect_ray(query)
/// 	if result and result.position.y >= 0.2:
/// 		successes += 1
/// var success_rate = float(successes) / float(attempts)
/// print("Success rate: ", success_rate)
/// ```
const TREE_GROW_SUCCESSRATE: f32 = 0.118762;

fn main() {
    println!("Hello, world!");
}
