extends Window

var is_main_spell_library = true # to detect if window is spell library - for spellcards options on rightclick

var spell_card_comp = preload("res://components/spell_card.tscn")
var spell_level_library_comp = preload("res://components/spell_level_library.tscn")
var custom_popup_comp = preload("res://components/custom_pop_up.tscn")
var popup_items = ["Learn Spell", "Print Spell", "Cast Spell"]

@onready var spell_libraries_container = $"VBoxContainer/SpellLevelLibs"

var last_database_query = ""

var spell_libraries = []

var character: Character = null #for learning spells
var spellbook_name = ""
var spells_all_arr = []
var spells_one_arr = []

var current_spellcard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/HBoxContainer/AllowedSpellsAll.text = var_to_str(spells_all_arr)
	$VBoxContainer/HBoxContainer/AllowedSpellsOne.text = var_to_str(spells_one_arr)
	var spell_array = Globals.spell_database.get_spells_from_database(spells_all_arr, spells_one_arr, self)
	fill_spell_library(spell_array)


func _on_search_button_pressed() -> void:
	#check validity of AllowedSpellsAll and AllowedSpellsOne inputs
	var spell_list_all = []
	var spell_list_one = []
	if $VBoxContainer/HBoxContainer/AllowedSpellsAll.text != "":
		spell_list_all = str_to_var($VBoxContainer/HBoxContainer/AllowedSpellsAll.text)
		if spell_list_all == null or not spell_list_all is Array :
			$AcceptDialog.dialog_text = "Aborting Search - Spell Filter not Array"
			$AcceptDialog.popup()
			return
		for string in spell_list_all:
			if not string is String or string == "":
				$AcceptDialog.dialog_text = "Aborting Search - " + str(string) + " not String"
				$AcceptDialog.popup()
				return
	if $VBoxContainer/HBoxContainer/AllowedSpellsOne.text != "":
		spell_list_one = str_to_var($VBoxContainer/HBoxContainer/AllowedSpellsOne.text)
		if spell_list_one == null or not spell_list_one is Array :
			$AcceptDialog.dialog_text = "Aborting Search - Spell Search not Array"
			$AcceptDialog.popup()
			return
		for string in spell_list_one:
			if not string is String or string == "":
				$AcceptDialog.dialog_text = "Aborting Search - " + str(string) + " not String"
				$AcceptDialog.popup()
				return
	#inputs are fine, apply changes
	spells_all_arr = spell_list_all
	spells_one_arr = spell_list_one
	var spell_array = Globals.spell_database.get_spells_from_database(spells_all_arr, spells_one_arr, self)
	clear_spell_library()
	fill_spell_library(spell_array)
	
	
func fill_spell_library(spell_array):
	var max_level = -1
	for spell in spell_array:
		var spell_level = spell["spell_level"]
		if spell_level > max_level: #create spell library containers
			for i in range(max_level + 1, spell_level + 1):
				print("GENERATING SPELLBOOK LEVEL " , i)
				var new_spell_level_library = spell_level_library_comp.instantiate()
				new_spell_level_library.spell_level = i
				new_spell_level_library.spellbook = self
				new_spell_level_library.name = "Lvl " + str(i)
				spell_libraries_container.add_child(new_spell_level_library)
				spell_libraries.append(new_spell_level_library)
			max_level = spell_level
				
		spell_libraries[spell_level].add_spell_to_library(spell)
	
func clear_spell_library():
	for child in spell_libraries_container.get_children():
		child.free()
	spell_libraries.clear()


func _on_pop_up_button_pressed() -> void:
	self.hide()
	self.force_native = not self.force_native
	if self.force_native:
		self.content_scale_factor = Globals.main_window.content_scale_factor
		self.size = self.size * self.content_scale_factor
	self.popup()


func _on_close_requested() -> void:
	self.hide()
	self.queue_free()


func _on_context_menu_item_pressed(item_index: Variant) -> void:
	if item_index == 0: #learn spell
		if character != null:
			character.add_spell_to_spellbook(current_spellcard.spell_dict, spellbook_name)
	elif item_index == 1: #print spell
		if current_spellcard == null:
			return
		var print_spellcard = spell_card_comp.instantiate()
		print_spellcard.print = true
		print_spellcard.spell_dict = current_spellcard.spell_dict
		Globals.roll_panel.add_node_to_rollpanel(print_spellcard)
		
	else: #cast spell TODO
		pass



#region Spell library edit buttons

func _on_save_preset_btn_pressed() -> void:
	$SaveFilterPresetNameDiag.popup()

func _on_save_preset_diag_btn_pressed() -> void:
	var preset_name = $SaveFilterPresetNameDiag/VBoxContainer/LineEdit.text
	if preset_name == "":
		return
	if Globals.spell_database.get_preset_from_db(preset_name) == null:
		Globals.spell_database.add_preset_to_db(preset_name, last_database_query)
	else:
		Globals.spell_database.edit_preset_in_db(preset_name, last_database_query)
	$SaveFilterPresetNameDiag.hide()

func _on_save_filter_preset_name_diag_close_requested() -> void:
	$SaveFilterPresetNameDiag.hide()

func _on_load_preset_btn_pressed() -> void:
	$LoadFilterPresetDiag.popup()

func _on_load_filter_preset_diag_btn_pressed() -> void:
	var preset_name = $LoadFilterPresetDiag/VBoxContainer/OptionButton.get_item_text($LoadFilterPresetDiag/VBoxContainer/OptionButton.get_selected_id())
	var query = Globals.spell_database.get_preset_from_db(preset_name)[1]
	var result_arr = Globals.spell_database.custom_select_query(query, self)
	clear_spell_library()
	fill_spell_library(result_arr)

func _on_load_filter_preset_diag_close_requested() -> void:
	$LoadFilterPresetDiag.hide()

func _on_add_keywords_btn_pressed() -> void:
	pass # Replace with function body.


func _on_set_keyword_color_btn_pressed() -> void:
	$SetColorToKeyword.popup()


func _on_import_spells_btn_pressed() -> void:
	$ImportFileDialog.popup()


func _on_export_spells_btn_pressed() -> void:
	pass # Replace with function body.


func _on_custom_sql_btn_pressed() -> void:
	pass # Replace with function body.


func _on_file_dialog_file_selected(path: String) -> void:
	print("file selected: ", path)
	#import spells from .csv
	var file = FileAccess.open(path, FileAccess.READ)
	var header = file.get_csv_line()
	#check if header contains spell_name field
	var name_found = false
	for entry in header:
		if entry == "spell_name":
			name_found = true
			break
	if not (name_found):
		$AcceptDialog.dialog_text = "Missing \"spell_name\" field in imported table"
		$AcceptDialog.popup()
		return
	#backup old spell library
	DirAccess.copy_absolute(Globals.base_dir_path + "/spells.db", Globals.base_dir_path + "/spells_backup.db")
	var spells_missing_name = false
	var spells_missing_spell_level = false
	var spells_wrong_spell_level = false
	while file.get_position() < file.get_length():
		var new_spell_dict = {}
		var new_spell_keywords = []
		var new_spell_attr_dict = {}
		var line = file.get_csv_line()
		if line.size() == header.size():
			for i in range(header.size()):
				if line[i] == "" or header[i] == "" or header[i] == "spell_id":
					continue
				elif header[i] == "keywords":
					new_spell_keywords.append(line[i])
				elif header[i] == "spell_level" or header[i] == "spell_name" or header[i] == "spellcard_name":
					new_spell_dict[header[i]] = line[i]
				elif header[i] == "spell_icon_path":
					if FileAccess.file_exists(line[i]):
						var image = Image.load_from_file(line[i])
						if image.is_empty():
							continue
						image.clear_mipmaps()
						image.resize(128, 128) #load image as 128 x 128 icon
						image.convert(Image.Format.FORMAT_RGB8)
						new_spell_dict["spell_icon"] = image.save_png_to_buffer() #save image data in dict
				elif header[i] == "spell_icon_blob":
					var image = Image.new()
					var error = image.load_png_from_buffer(line[i].to_utf8_buffer())
					if error == Error.OK:
						new_spell_dict["spell_icon"] =  image.get_data() #save image data in dict
				else:
					new_spell_attr_dict[header[i]] = line[i]
			if not new_spell_dict.has("spell_name"):
				spells_missing_name = true
				continue # discard spell and print warning
			if not new_spell_dict.has("spell_level"):
				spells_missing_spell_level = true
				new_spell_dict["spell_level"] = 0# add spell as lvl 0 and print warning
			else: #check valid int
				if not new_spell_dict["spell_level"].is_valid_int():
					new_spell_dict["spell_level"] = 0
					spells_wrong_spell_level = true
					continue
			new_spell_dict["spell_attributes"] = var_to_str(new_spell_attr_dict)
		Globals.spell_database.add_spell_to_db(new_spell_dict, new_spell_keywords)
	$AcceptDialog.dialog_text = ""
	if spells_missing_name:
		$AcceptDialog.dialog_text += "spells with no spell_name were discarded\n"
	if spells_missing_spell_level:
		$AcceptDialog.dialog_text += "spells with no spell_level were added as lvl 0 spells\n"
	if spells_wrong_spell_level:
		$AcceptDialog.dialog_text += "spells with non integer spell_level were discarded\n"
	if spells_missing_name or spells_missing_spell_level or spells_wrong_spell_level:
		$AcceptDialog.popup()
		
		
		
		
				
				
					
				
					
					
					 


func _on_file_dialog_canceled() -> void:
	pass # Replace with function body.


func _on_add_spellcard_btn_pressed() -> void:
	$SpellcardFileDialog.popup()


func _on_spellcard_file_dialog_file_selected(path: String) -> void:
	print("file selected: ", path)
	var spell_card_name = path.get_basename().get_file()
	if (Globals.spell_database.get_spellcard_from_db(spell_card_name) != null):
		$SpellcardOverwriteConfirmationDialog.set_meta("path", path)
		$SpellcardOverwriteConfirmationDialog.popup()
		return
	var comp_arr: Array = []
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			print("file is null")
			return
		comp_arr = str_to_var(file.get_as_text())
		print(" DEBUG : ", comp_arr)
		file.close()
		Globals.spell_database.add_spellcard_to_db(spell_card_name, comp_arr)
	else:
		$AcceptDialog.dialog_text = "ERROR Failed to open specified path!"
		$AcceptDialog.popup()


func _on_spellcard_overwrite_confirmation_dialog_confirmed() -> void:
	var path = $SpellcardOverwriteConfirmationDialog.get_meta("path")
	var spell_card_name = path.get_basename().get_file()
	var comp_arr: Array = []
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			print("file is null")
			return
		comp_arr = str_to_var(file.get_as_text())
		print(" DEBUG : ", comp_arr)
		file.close()
		Globals.spell_database.edit_spellcard_in_db(spell_card_name, comp_arr)
	else:
		$AcceptDialog.dialog_text = "ERROR Failed to open specified path!"
		$AcceptDialog.popup()


func _on_spellcard_overwrite_confirmation_dialog_canceled() -> void:
	pass # Replace with function body.


func _on_set_color_to_keyword_close_requested() -> void:
	$SetColorToKeyword.hide()


func _on_keyword_color_apply_btn_pressed() -> void:
	var keyword = $SetColorToKeyword/VBoxContainer/KeywordLineEdit.text
	var priority = $SetColorToKeyword/VBoxContainer/HBoxContainer/KeywordPrioritySpinBox.value
	var color = $SetColorToKeyword/VBoxContainer/HBoxContainer2/KeywordColorPickerBtn.color
	Globals.spell_database.add_color_to_keyword_in_db(keyword, color, priority)
	$SetColorToKeyword.hide()
