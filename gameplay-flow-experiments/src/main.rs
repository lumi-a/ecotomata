use ordered_float::OrderedFloat;
use rand::prelude::*;
use rand_distr::Exp;
use std::collections::HashSet;

type F = OrderedFloat<f64>;

const TREE_GROW_SUCCESSRATE: F = OrderedFloat(0.118762);
const TREE_MIN_DISTANCE2: F = OrderedFloat(0.2 * 0.2 / (7.0 * 7.0));
const TREE_NEIGHBORSHIP_DISTANCE2: F = OrderedFloat(1.5 * 1.5 / (7.0 * 7.0));

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Coor(F, F);
impl Coor {
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
    money: F,
    t: F,
    next_tree: F,
    next_lightning: F,
    next_tree_upgrade: F,
    next_lightning_upgrade: F,
    tree_level: i32,
    lightning_level: i32,
    tree_level_cost: Box<dyn Fn(i32) -> f64>,
    lightning_level_cost: Box<dyn Fn(i32) -> f64>,
    tree_level_to_rate: Box<dyn Fn(i32) -> F>,
    lightning_level_to_rate: Box<dyn Fn(i32) -> F>,
}

impl Game {
    fn update_t(self: &mut Self, new_t: F) {
        self.money += (new_t - self.t) * OrderedFloat(self.trees.len() as f64);
        self.t = new_t;
    }
    fn step(self: &mut Self) {
        let mut rng = rand::thread_rng();

        // Determine next event
        if self.next_tree < self.next_lightning
            && self.next_tree < self.next_tree_upgrade
            && self.next_tree < self.next_lightning_upgrade
        {
            self.update_t(self.next_tree);

            self.try_growing_tree();
            self.next_tree = self.t
                + OrderedFloat(
                    Exp::new((self.tree_level_to_rate)(self.tree_level).into())
                        .unwrap()
                        .sample(&mut rng),
                );
        } else if self.next_lightning < self.next_tree_upgrade
            && self.next_lightning < self.next_lightning_upgrade
        {
            self.update_t(self.next_lightning);
            self.shoot_lightning();
            self.next_lightning = self.t
                + OrderedFloat(
                    Exp::new((self.lightning_level_to_rate)(self.lightning_level).into())
                        .unwrap()
                        .sample(&mut rng),
                );
        } else if self.next_tree_upgrade < self.next_lightning_upgrade {
            self.update_t(self.next_tree_upgrade);
            if self.money >= OrderedFloat((self.tree_level_cost)(self.tree_level + 1)) {
                self.money -= (self.tree_level_cost)(self.tree_level + 1);
                self.tree_level += 1;
            }
        } else {
            self.update_t(self.next_lightning_upgrade);
            if self.money >= OrderedFloat((self.lightning_level_cost)(self.lightning_level + 1)) {
                self.money -= (self.lightning_level_cost)(self.lightning_level + 1);
                self.lightning_level += 1;
            }
        }

        self.update_next_upgrades();
    }

    fn update_next_upgrades(self: &mut Self) {
        self.next_tree_upgrade = self.t
            + OrderedFloat((self.tree_level_cost)(self.tree_level + 1) as f64)
                / OrderedFloat(self.trees.len() as f64);
        self.next_lightning_upgrade = self.t
            + OrderedFloat((self.lightning_level_cost)(self.lightning_level + 1) as f64)
                / OrderedFloat(self.trees.len() as f64);
    }

    fn try_growing_tree(self: &mut Self) {
        let mut rng = rand::thread_rng();
        if rng.gen_bool(TREE_GROW_SUCCESSRATE.into()) {
            let new_tree = Coor(OrderedFloat(rng.gen()), OrderedFloat(rng.gen()));
            if self
                .trees
                .iter()
                .all(|tree| tree.dist2(new_tree) >= TREE_MIN_DISTANCE2)
            {
                self.trees.insert(new_tree);
            }
        }
    }

    fn shoot_lightning(self: &mut Self) {
        let mut rng = rand::thread_rng();
        if let Some(tree) = self.trees.iter().cloned().choose(&mut rng) {
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
            self.trees.retain(|tree| !hit_trees.contains(tree));
        }
    }
}

fn main() {
    let mut game = Game {
        trees: HashSet::new(),
        money: OrderedFloat(0.0),
        t: OrderedFloat(0.0),
        next_tree: OrderedFloat(1.0),
        next_lightning: OrderedFloat(5.0),
        next_tree_upgrade: OrderedFloat(10.0),
        next_lightning_upgrade: OrderedFloat(20.0),
        tree_level: 1,
        lightning_level: 1,
        tree_level_cost: Box::new(|level| level as f64 * 15.0),
        lightning_level_cost: Box::new(|level| level as f64 * 15.0),
        tree_level_to_rate: Box::new(|level| OrderedFloat(level as f64 * 10.0)),
        lightning_level_to_rate: Box::new(|level| OrderedFloat(1.0 - level as f64 / 10.0)),
    };
    game.update_next_upgrades();

    for _ in 0..10000 {
        game.step();
        println!(
            "Time: {:.2}, Trees: {}, Money: {}, Tree Level: {}, Lightning Level: {}",
            game.t,
            game.trees.len(),
            game.money,
            game.tree_level,
            game.lightning_level
        );
    }
}
