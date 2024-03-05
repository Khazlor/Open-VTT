extends Control

@onready var tree = $PanelContainer/Tree

var item_dict = {
	"category": "",
	"name": "item",
	"icon": "",
	"weight": 0,
	"count": 1,
	"description": "",
	"attributes": {},
	"attribute_modifiers": [],
	"macros": {},
	"equipped": false
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#changed count
func _on_tree_item_edited():
	var tree_item = tree.get_selected()
	var item = tree_item.get_meta("item_dict")
	var weight_diff = (tree_item.get_range(2) - item["count"]) * tree_item.get_range(3)
	tree.change_weight(tree_item, weight_diff) #change total weights
	item["count"] = tree_item.get_range(2)
