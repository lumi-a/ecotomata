extends Control

# Controls everything related to
# buying, displaying, and managing upgrades.

signal bought_flowers

var orb_label: Label
var tree_buy_button: Button
var tree_label: Label
var tree_range: Range
var flower_buy_button: Button
var flower_label: Label
var flower_range: Range

@export var orbs: int = 0
@export var tree_level: int = 0
@export var tree_max_level: int = 8
@export var flower_level: int = 0
@export var flower_max_level: int = 5

func _ready() -> void:
	orb_label = $PanelContainer/VBoxContainer/OrbContainer/OrbLabel
	
	tree_buy_button = $PanelContainer/VBoxContainer/TreesContainer/TreesBuy
	tree_buy_button.connect("pressed", buy_tree)
	tree_buy_button.text = "+ Trees: O" + str(tree_cost)
	tree_label = $PanelContainer/VBoxContainer/TreesContainer/TreesDescription
	tree_range = $PanelContainer/VBoxContainer/TreesContainer/TreesRange
	tree_range.value = 0
	tree_range.min_value = 0
	tree_range.max_value = tree_max_level
	
	flower_buy_button = $PanelContainer/VBoxContainer/FlowersContainer/FlowersBuy
	flower_buy_button.connect("pressed", buy_flower)
	flower_buy_button.text = "+ Flowers: O" + str(flower_cost)
	flower_label = $PanelContainer/VBoxContainer/FlowersContainer/FlowersDescription
	flower_range = $PanelContainer/VBoxContainer/FlowersContainer/FlowersRange
	flower_range.value = 0
	flower_range.min_value = 0
	flower_range.max_value = flower_max_level


var tree_cost: int = 10
func update_tree_button_text():
	if tree_level < tree_max_level:
		tree_buy_button.text = "+ Trees: O" + str(tree_cost)
	else:
		tree_buy_button.text = "+ Trees: Max!"
		flower_buy_button.disabled = true
func buy_tree():
	if tree_cost <= orbs:
		orbs -= tree_cost
		tree_level += 1
		tree_range.value = tree_level
		if tree_level < tree_max_level:
			tree_cost = 10 * round((tree_level + 1) ** 2.5)
		update_tree_button_text()
		tree_buy_button.disabled = true

var flower_cost: int = 20
func update_flower_button_text():
	if flower_level < flower_max_level:
		flower_buy_button.text = "+ Flowers: O" + str(flower_cost)
	else:
		flower_buy_button.text = "+ Flowers: Max!"
		flower_buy_button.disabled = true
func buy_flower():
	if flower_cost <= orbs:
		bought_flowers.emit()
		orbs -= flower_cost
		flower_level += 1
		flower_range.value = flower_level
		if flower_level < flower_max_level:
			flower_cost = 20 * round((flower_level + 1) ** 3)
		update_flower_button_text()
		flower_buy_button.disabled = true

func _process(_delta):
	orb_label.text = str(orbs)
	
	tree_buy_button.disabled = orbs < tree_cost or tree_level >= tree_max_level
	flower_buy_button.disabled = orbs < flower_cost or flower_level >= flower_max_level