extends Window

var selected = [] #list of selected objects with character or inventory
@onready var tabs = $TabContainer

var inventory_comp = preload("res://components/inventory.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print(selected)
	for object in selected:
		if "character" in object:
			print("char")
			var new_inventory = inventory_comp.instantiate()
			new_inventory.get_node("PanelContainer/Tree").items = object.character.items
			new_inventory.get_node("PanelContainer/Tree").equipped_items = object.character.equipped_items
			new_inventory.get_node("PanelContainer/Tree").character = object.character
			tabs.add_child(new_inventory)
			new_inventory.name = object.character.name
		elif object.has_meta("inventory"):
			print("inv")
			var new_inventory = inventory_comp.instantiate()
			new_inventory.get_node("PanelContainer/Tree").items = object.get_meta("inventory")
			tabs.add_child(new_inventory)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_requested():
	self.hide()
	self.queue_free()