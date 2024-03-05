extends PanelContainer

var attr_name = ""
var item_attr_dict = {
	"value" = "",
	"description" = "",
	"show" = false
}
@onready var item_dict = get_viewport().item_dict

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/Name/NameTextEdit.text = attr_name
	$VBoxContainer/Value/ValueTextEdit.text = item_attr_dict["value"]
	$VBoxContainer/Description/DescriptionTextEdit.text = item_attr_dict["description"]
	$VBoxContainer/Show/CheckBox.button_pressed = item_attr_dict["show"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#change attribute name
func _on_apply_name_button_pressed():
	var name = $VBoxContainer/Name/NameTextEdit.text
	if name != attr_name:
		item_dict["attributes"].erase(attr_name)
		attr_name = name
		var i = 0
		#get unique name
		while item_dict["attributes"].has(name):
			name = attr_name + "_" + i.to_string()
		$VBoxContainer/Name/NameTextEdit.text = name
		attr_name = name
		item_dict["attributes"][name] = item_attr_dict


func _on_value_text_edit_text_changed():
	item_attr_dict["value"] = $VBoxContainer/Value/ValueTextEdit.text


func _on_description_text_edit_text_changed():
	item_attr_dict["description"] = $VBoxContainer/Description/DescriptionTextEdit.text


func _on_check_box_toggled(button_pressed):
	item_attr_dict["show"] = button_pressed


func _on_duplicate_button_pressed():
	#get unique name
	var name = $VBoxContainer/Name/NameTextEdit.text
	var i = 0
	while item_dict["attributes"].has(name):
		name = attr_name + "_" + i.to_string()
	var new_item_attr_setting = self.duplicate(5)
	new_item_attr_setting.attr_name = name
	add_sibling(new_item_attr_setting)
	item_dict["attributes"][name] = new_item_attr_setting.item_attr_dict


func _on_delete_button_pressed():
	item_dict.erase(attr_name)
	get_parent().remove_child(self)
	self.queue_free()
