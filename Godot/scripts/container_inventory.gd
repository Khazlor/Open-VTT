#Author: Vladimír Horák
#Desc:
#Script for Window with character and container inventory - pressing I opens for all selected

extends Window

var selected = [] #list of selected objects with character or inventory
@onready var tabs = $TabContainer

var inventory_comp = preload("res://components/inventory.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print(selected)
	for object in selected:
		var new_inventory = inventory_comp.instantiate()
		var tree = new_inventory.get_node("PanelContainer/Tree")
		if "character" in object:
			print("char")
			tree.items = object.character.items
			tree.equipped_items = object.character.equipped_items
			tree.character = object.character
			tabs.add_child(new_inventory)
			new_inventory.name = object.character.name
		elif object.has_meta("inventory"):
			print("inv")
			tree.items = object.get_meta("inventory")
			tree.container = object
			tabs.add_child(new_inventory)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_requested():
	self.hide()
	self.queue_free()
