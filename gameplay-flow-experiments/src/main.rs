use std::collections::HashSet;

use ordered_float::OrderedFloat;
use rand::prelude::*;
use rand_distr::Exp;

type F = OrderedFloat<f64>;

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
const TREE_GROW_SUCCESSRATE: F = OrderedFloat(0.118762);
const TREE_MIN_DISTANCE: F = OrderedFloat(0.2 / 7.0);
const TREE_MIN_DISTANCE2: F = OrderedFloat(0.2 * 0.2 / (7.0 * 7.0));
const TREE_NEIGHBORSHIP_DISTANCE: F = OrderedFloat(1.5 / 7.0);
const TREE_NEIGHBORSHIP_DISTANCE2: F = OrderedFloat(1.5 * 1.5 / 7.0 * 7.0);

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Coor(F, F);
impl Coor {
    /*
    fn dist(a: Coor, b: Coor) -> F {
        ((a.0 - b.0).powi(2) + (a.1 - b.1).powi(2)).sqrt()
    }
    */
    fn dist2(self: Self, b: Coor) -> F {
        OrderedFloat((self.0 - b.0).powi(2) + (self.1 - b.1).powi(2))
    }
}

enum Event {
    TreeGrow(Coor),
    Lightning,
    UpgradeTrees,
    UpgradeLightning,
}

struct Game {
    trees: HashSet<Coor>,
    money: i32,
    t: F,
    next_tree: F,
    next_lightning: F,
    next_tree_upgrade: F,
    next_lightning_upgrade: F,
    tree_level: i32,
    lightning_level: i32,
    tree_level_cost: Box<dyn Fn(i32) -> i32>,
    lightning_level_cost: Box<dyn Fn(i32) -> i32>,
    tree_level_to_rate: Box<dyn Fn(i32) -> F>,
    lightning_level_to_rate: Box<dyn Fn(i32) -> F>,
}

impl Game {
    fn step(self: &mut Self) {
        let mut rng = rand::thread_rng();

        // What's the next event?
        if self.next_tree < self.next_lightning
            && self.next_tree < self.next_tree_upgrade
            && self.next_tree < self.next_lightning_upgrade
        {
            self.t = self.next_tree;
            self.try_growing_tree();

            let tree_upgrade_rate: f64 = (self.tree_level_to_rate)(self.tree_level).into();
            self.next_tree_upgrade = self.t + Exp::new(tree_upgrade_rate).unwrap().sample(&mut rng);
        } else if self.next_lightning < self.next_tree_upgrade
            && self.next_lightning < self.next_lightning_upgrade
        {
            self.t = self.next_lightning;
            self.shoot_lightning();

            let lightning_upgrade_rate: f64 =
                (self.lightning_level_to_rate)(self.lightning_level).into();
            self.next_lightning_upgrade =
                self.t + Exp::new(lightning_upgrade_rate).unwrap().sample(&mut rng);
        } else if self.next_tree_upgrade < self.next_lightning_upgrade {
            self.t = self.next_tree_upgrade;
            self.money -= ((self.tree_level_cost)(self.tree_level + 1)) as i32;
        } else {
            self.t = self.next_lightning_upgrade;
        }
        self.update_next_upgrades();
    }

    fn update_next_upgrades(self: &mut Self) {
        self.next_tree_upgrade = self.t
            + OrderedFloat((self.tree_level_cost)(self.tree_level + 1) as f64)
                / OrderedFloat(self.trees.len() as f64);
        self.next_tree_upgrade = self.t
            + OrderedFloat((self.tree_level_cost)(self.tree_level + 1) as f64)
                / OrderedFloat(self.trees.len() as f64);
    }

    fn try_growing_tree(self: &mut Self) {
        let mut rng = rand::thread_rng();
        if rng.gen_bool(TREE_GROW_SUCCESSRATE.into()) {
            let new_tree: Coor = Coor(OrderedFloat(rng.gen()), OrderedFloat(rng.gen()));
            for tree in &self.trees {
                if tree.dist2(new_tree) < TREE_MIN_DISTANCE2 {
                    return;
                }
            }
            self.trees.insert(new_tree);
        }
    }

    fn shoot_lightning(self: &mut Self) {
        let mut rng: ThreadRng = rand::thread_rng();
        // Pick random tree
        let maybe_tree = self.trees.clone().into_iter().choose(&mut rng);
        if let Some(tree) = maybe_tree {
            let mut hit_trees = HashSet::new();
            hit_trees.insert(tree);

            fn recursive_hit(tree: Coor, trees: &HashSet<Coor>, hit_trees: &mut HashSet<Coor>) {
                for other_tree in trees {
                    if other_tree.dist2(tree) < TREE_NEIGHBORSHIP_DISTANCE2
                        && hit_trees.insert(*other_tree)
                    {
                        recursive_hit(*other_tree, trees, hit_trees);
                    }
                }
            }

            recursive_hit(tree, &self.trees, &mut hit_trees);

            self.trees = self.trees.difference(&hit_trees).cloned().collect();
        }
    }
}

fn main() {
    println!("Hello, world!");
}
