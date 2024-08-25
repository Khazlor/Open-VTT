#Author: Vladimír Horák
#Desc:
#Script for inventory section of character sheet - most functionality in inventory_tree

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

#changed count
func _on_tree_item_edited():
	var tree_item = tree.get_selected()
	var item = tree_item.get_meta("item_dict")
	var weight_diff = (tree_item.get_range(2) - item["count"]) * tree_item.get_range(3)
	tree.change_weight(tree_item, weight_diff) #change total weights
	item["count"] = tree_item.get_range(2)
	tree.character.emit_signal("inv_changed")
