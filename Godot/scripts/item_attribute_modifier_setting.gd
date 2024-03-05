extends PanelContainer

var item_attr_mod_dict = {
	"attribute" = "",
	"type" = "",
	"value" = "",
	"mode" = ModMode.ADD,
	"priority" = 0
}

enum ModMode {
	ADD,
	SUB,
	SET,
	MAX,
	MIN,
	MUL,
	DIV,
	ADD_STR
}

@onready var item_dict = get_viewport().item_dict

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/Attribute/AttributeLineEdit.text = item_attr_mod_dict["attribute"]
	$VBoxContainer/Type/TypeLineEdit.text = item_attr_mod_dict["type"]
	$VBoxContainer/Value/ValueTextEdit.text = item_attr_mod_dict["value"]
	$VBoxContainer/Mode/ModeOptionButton.selected = item_attr_mod_dict["mode"]
	$VBoxContainer/Priority/PrioritySpinBox.value = item_attr_mod_dict["priority"]
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_duplicate_button_pressed():
	var new_item_attr_setting = self.duplicate(5)
	add_sibling(new_item_attr_setting)
	item_dict["attribute_modifiers"].append(new_item_attr_setting.item_attr_mod_dict)


func _on_delete_button_pressed():
	item_dict["attribute_modifiers"].erase(item_attr_mod_dict)
	get_parent().remove_child(self)
	self.queue_free()


func _on_attribute_line_edit_text_submitted():
	print("attribute changed")
	item_attr_mod_dict["attribute"] = $VBoxContainer/Attribute/AttributeLineEdit.text


func _on_type_line_edit_text_submitted():
	item_attr_mod_dict["type"] = $VBoxContainer/Type/TypeLineEdit.text


func _on_value_text_edit_text_changed():
	item_attr_mod_dict["value"] = $VBoxContainer/Value/ValueTextEdit.text


func _on_option_button_item_selected(index):
	item_attr_mod_dict["mode"] = index
	

