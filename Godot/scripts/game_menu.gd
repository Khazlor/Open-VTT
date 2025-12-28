extends Window

var new_settings_dict = {}
var settings_loaded = false
var keybinds_loaded = false

var action_remap_btn_res = preload("res://addons/input_map_demo/ActionRemapButton.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _on_window_input(event: InputEvent) -> void:
	if event is InputEventKey: #handle keyboard events
		if Input.is_action_just_pressed("Escape"):
			reset_menu()
			self.hide()


func _on_close_requested() -> void:
	Globals.main_window.content_scale_factor = Globals.settings.settings_dict["ui_scale"]
	self.hide()


func _on_quit_btn_pressed() -> void:
	if Globals.enet_peer != null and Globals.lobby.check_is_server():
		$ConfirmationDialog.popup_centered()
	else:
		multiplayer.multiplayer_peer = null #terminate multiplayer
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_maps_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Maps.tscn")


func _on_confirmation_dialog_confirmed() -> void:
	multiplayer.multiplayer_peer = null #terminate multiplayer
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_confirmation_dialog_canceled() -> void:
	$ConfirmationDialog.hide()


func _on_help_btn_pressed() -> void:
	self.hide()
	$"../Draw/TutorialWindow".popup()


func _on_ui_scale_spin_box_value_changed(value: float) -> void:
	var factor = value/100.0
	Globals.main_window.content_scale_factor = factor
	new_settings_dict["ui_scale"] = factor


func _on_player_name_line_edit_text_changed(new_text: String) -> void:
	new_settings_dict["player_name"] = new_text


func _on_apply_btn_pressed() -> void:
	for key in new_settings_dict.keys():
		Globals.settings.settings_dict[key] = new_settings_dict[key]
	Globals.settings.apply_settings()
	Globals.settings.save_settings()
	if not KeyPersistence.temp_keymaps.is_empty():
		KeyPersistence.apply_temp_keymap()
	reset_menu()
	self.hide()

func reset_menu():
	$Menu.visible = true
	$ConfirmationDialog.hide()
	$Settings.visible = false
	$Settings/TabContainer.current_tab = 0


func _on_cancel_btn_pressed() -> void:
	Globals.main_window.content_scale_factor = Globals.settings.settings_dict["ui_scale"]
	if not KeyPersistence.temp_keymaps.is_empty():
		#discard changes and reset key mapping
		KeyPersistence.temp_keymaps.clear()
		for child in $"Settings/TabContainer/Key Mapping/VBoxContainer/MarginContainer/HBoxContainer/LabelVBox".get_children():
			child.queue_free()
		for child in $"Settings/TabContainer/Key Mapping/VBoxContainer/MarginContainer/HBoxContainer/EditVBox".get_children():
			child.queue_free()
		keybinds_loaded = false
	reset_menu()
	self.hide()


func _on_options_btn_pressed() -> void:
	$Menu.visible = false
	$Settings.visible = true
	if not settings_loaded:
		load_settings()
	
func load_settings():
	if Globals.settings.settings_dict.has("ui_scale"):
		$Settings/TabContainer/Visual/MarginContainer/HBoxContainer/EditVBox/UIScaleSpinBox.set_value_no_signal(Globals.settings.settings_dict["ui_scale"] * 100)
	if Globals.settings.settings_dict.has("player_name"):
		$Settings/TabContainer/Multiplayer/MarginContainer/HBoxContainer/EditVBox/PlayerNameLineEdit.text = Globals.settings.settings_dict["player_name"]
	settings_loaded = true
		
func load_keybinds():
	var labels = $"Settings/TabContainer/Key Mapping/VBoxContainer/MarginContainer/HBoxContainer/LabelVBox"
	var edits = $"Settings/TabContainer/Key Mapping/VBoxContainer/MarginContainer/HBoxContainer/EditVBox"
	for action in InputMap.get_actions():
		var label = Label.new()
		label.custom_minimum_size.y = 40
		label.text = action
		labels.add_child(label)
		var button = action_remap_btn_res.instantiate()
		button.action = action
		edits.add_child(button)
	keybinds_loaded = true

func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == 2:
		if not keybinds_loaded:
			load_keybinds()
