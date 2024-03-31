extends PanelContainer

@onready var character_sheet = $"../../../../../../../../"

var attr_dict = {
	"name": "",
	"edit": false,
	"icon": "",
	"image": ""
	}

@onready var parent = self.get_parent()

@onready var dialog = $TokenImageFileDialog
var dialog_target

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/HBoxContainer/AttrName.text = attr_dict["name"]
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer/CheckBox.button_pressed = attr_dict["edit"]
	var image = Globals.load_texture(attr_dict["icon"])
	if image != null:
		$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer2/PanelContainer/IconTextureButton.texture_normal = image
	image = Globals.load_texture(attr_dict["image"])
	if image != null:
		$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer3/PanelContainer/ImageTextureButton.texture_normal = image


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_attr_name_text_submitted(new_text):
	attr_dict["name"] = new_text
	character_sheet.character.emit_signal("attr_bubbles_changed")
	
	
func _on_add_button_pressed():
	var new_attr_bubble_settings = self.duplicate(5)
	new_attr_bubble_settings.attr_dict = attr_dict.duplicate(true)
	character_sheet.character.attr_bubbles.insert(self.get_index()+1, new_attr_bubble_settings.attr_dict)
	add_sibling(new_attr_bubble_settings)
	character_sheet.character.emit_signal("attr_bubbles_changed")


func _on_move_up_button_pressed():
	var i = self.get_index()
	if i == 0: # first - move to back
		parent.move_child(self, -1)
		character_sheet.character.attr_bubbles.pop_front()
		character_sheet.character.attr_bubbles.append(attr_dict)
	else:
		parent.move_child(self, i - 1)
		character_sheet.character.attr_bubbles[i] = character_sheet.character.attr_bubbles[i - 1]
		character_sheet.character.attr_bubbles[i - 1] = attr_dict
	character_sheet.character.emit_signal("attr_bubbles_changed")


func _on_move_down_button_pressed():
	var i = self.get_index()
	if i == character_sheet.character.attr_bubbles.size() - 1: # last - move to front
		parent.move_child(self, 0)
		character_sheet.character.attr_bubbles.pop_back()
		character_sheet.character.attr_bubbles.push_front(attr_dict)
	else:
		parent.move_child(self, self.get_index() + 1)
		character_sheet.character.attr_bubbles[i] = character_sheet.character.attr_bubbles[i + 1]
		character_sheet.character.attr_bubbles[i + 1] = attr_dict
	character_sheet.character.emit_signal("attr_bubbles_changed")


func _on_remove_button_pressed():
	character_sheet.character.attr_bubbles.remove_at(self.get_index())
	self.queue_free()
	character_sheet.character.emit_signal("attr_bubbles_changed")


func _on_check_box_toggled(button_pressed):
	attr_dict["edit"] = button_pressed
	character_sheet.character.emit_signal("attr_bubbles_changed")


func _on_icon_texture_button_pressed():
	dialog_target = 1
	dialog.popup()


func _on_image_texture_button_pressed():
	dialog_target = 2
	dialog.popup()


func _on_token_image_file_dialog_file_selected(path):
	path = await Globals.lobby.handle_file_transfer(path)
	if dialog_target == 1: #icon
		attr_dict["icon"] = path
		$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer2/PanelContainer/IconTextureButton.texture_normal = Globals.load_texture(path)
	else: #background image
		attr_dict["image"] = path
		$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer3/PanelContainer/ImageTextureButton.texture_normal = Globals.load_texture(path)
	character_sheet.character.emit_signal("attr_bubbles_changed")

