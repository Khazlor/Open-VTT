extends Control

@onready var tree: Tree = $Tree

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")

# Called when the node enters the scene tree for the first time.
func _ready():
	tree.create_item() #root
	tree.hide_root = true
	var root = tree.create_item()
	root.set_text(0, "layer_group_1")
	root.add_button(0, button_visible)
	var child = tree.create_item(root)
	child.set_text(0, "layer_1")
	child.add_button(0, button_visible)
	
	root = tree.create_item()
	root.set_text(0, "layer_group_2")
	root.add_button(0, button_visible)
	child = tree.create_item(root)
	child.set_text(0, "layer_2")
	child.add_button(0, button_visible)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

