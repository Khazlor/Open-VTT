#Author: Vladimír Horák
#Desc:
#Script for item creation window used to create and modify items

extends Window

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

@onready var attr_list = $ScrollContainer/VBoxContainer/Attributes/VBoxContainer
@onready var attr_mod_list = $ScrollContainer/VBoxContainer/AttributeModifiers/VBoxContainer

@onready var item_attribute_setting = preload("res://components/item_attribute_setting.tscn")
@onready var item_attribute_modifier_setting = preload("res://components/item_attribute_modifier_setting.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	$ScrollContainer/VBoxContainer/Category/HBoxContainer/CategoryTextEdit.text = item_dict["category"]
	$ScrollContainer/VBoxContainer/Name/HBoxContainer/NameTextEdit.text = item_dict["name"]
	$ScrollContainer/VBoxContainer/Weight/HBoxContainer/WeightSpinBox.value = item_dict["weight"]
	$ScrollContainer/VBoxContainer/Count/HBoxContainer/CountSpinBox.value = item_dict["count"]
	$ScrollContainer/VBoxContainer/Description/HBoxContainer/DescriptionTextEdit.text = item_dict["description"]
	var image = Globals.load_texture(item_dict["icon"])
	if image != null:
		$ScrollContainer/VBoxContainer/Icon/HBoxContainer/TextureButton.texture_normal = image
		
	#attributes
	for attr in item_dict["attributes"]:
		var item_attribute = item_attribute_setting.instantiate()
		item_attribute.attr_name = attr
		item_attribute.item_attr_dict = item_dict["attributes"][attr]
		attr_list.add_child(item_attribute)
		
	#attributes
	for attr_mod_dict in item_dict["attribute_modifiers"]:
		var item_attr_mod = item_attribute_modifier_setting.instantiate()
		item_attr_mod.item_attr_mod_dict = attr_mod_dict
		attr_mod_list.add_child(item_attr_mod)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_category_text_edit_text_changed():
	item_dict["category"] = $ScrollContainer/VBoxContainer/Category/HBoxContainer/CategoryTextEdit.text


func _on_name_text_edit_text_changed():
	item_dict["name"] = $ScrollContainer/VBoxContainer/Name/HBoxContainer/NameTextEdit.text
	

func _on_weight_spin_box_value_changed(value):
	item_dict["weight"] = $ScrollContainer/VBoxContainer/Weight/HBoxContainer/WeightSpinBox.value


func _on_count_spin_box_value_changed(value):
	item_dict["count"] = $ScrollContainer/VBoxContainer/Count/HBoxContainer/CountSpinBox.value


func _on_description_text_edit_text_changed():
	item_dict["description"] = $ScrollContainer/VBoxContainer/Description/HBoxContainer/DescriptionTextEdit.text


func _on_texture_button_pressed():
	$ImageFileDialog.popup()


func _on_image_file_dialog_file_selected(path):
	path = await Globals.lobby.handle_file_transfer(path)
	item_dict["icon"] = path
	$ScrollContainer/VBoxContainer/Icon/HBoxContainer/TextureButton.texture_normal = load(path)


func _on_attribute_add_button_pressed():
	var item_attribute = item_attribute_setting.instantiate()
	#get unique name
	var name = "new_attribute"
	var i = 0
	while item_dict["attributes"].has(name):
		name = item_attribute.attr_name + "_" + i.to_string()
	item_attribute.attr_name = name
	item_dict["attributes"][name] = item_attribute.item_attr_dict
	attr_list.add_child(item_attribute)


func _on_close_requested():
	print("close requested")
	hide()


func _on_attribute_mod_add_button_pressed():
	var item_attr_modifier = item_attribute_modifier_setting.instantiate()
	item_dict["attribute_modifiers"].append(item_attr_modifier.item_attr_mod_dict)
	attr_mod_list.add_child(item_attr_modifier)
