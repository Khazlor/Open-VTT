#Author: Vladimír Horák
#Desc:
#Resource for saving character data

extends Resource
class_name Character

@export var name = ""
@export var attributes = {} #dictionary for all attributes of character
var attribute_modifiers = {} #dictionary of all attribute modifiers (deflection bonus to AC from ring of deflection, etc.)
@export var global = false #global characters are shared between campaings
@export var singleton = false #all tokens have linked attributes
@export var save_as_token = false #save character only as part of token on map
@export var player_character = true
@export var char_sheet_path = ""

@export var spellbooks: Dictionary = {} #dict of all character spell casting classes (spellbooks) with their settings, spells, spells slots in a dict
#@export var spells = {} #dict of spellcasting classes with array of known spells for each
#@export var spell_slots = {} #dict of spellcasting classes with array of spell_slots for each level - tracking of prepared spells and spells slots
							 #{SpellBookOfClass: [spell level array[spell slot array for the spell level[spell_dict, already_cast_bool]]]}

@export var token_shape: StringName = &"Square"
@export var token_size: Vector2 = Vector2(70,70)
@export var token_scale: Vector2 = Vector2(1,1)
@export var token_outline_width: float = 5
@export var token_outline_color: Color = Color.BLACK
@export var token_outline_faction_color: bool = true
@export var token_texture: String #path to texture
@export var token_texture_offset: Vector2 = Vector2(0,0)
@export var token_texture_scale: Vector2 = Vector2(1,1)

@export var items = [] #list of items in inventory
var equipped_items = [] #list of equipped items - does not get saved - saved in equip_slots
@export var equip_slots = [[], [], []] #list for left, middle, right equipment slots
@export var bars = [] #list of all character bars
@export var attr_bubbles = [] #list of character attributes that are displayed in bubbles
@export var macros = {} #dict of all macros
@export var macros_in_bar = {} #dict of all macros in action bar

var singleton_dict_key

var tree_item: TreeItem
var token

signal get_token_request()
signal get_token_response()

signal token_changed()
signal bars_changed()
signal attr_bubbles_changed()
signal attr_created(attr: StringName, value)
signal attr_removed(attr: StringName)
signal attr_updated(attr: StringName, remote)
signal macro_bar_changed()
signal equip_slots_changed(equip_slot_dict, side: int, new: bool)
signal equipped_item_changed(item)
signal item_equipped(item)
signal item_unequipped(item)
signal reload_equip_slot(slot_dict)
signal unequip_item_from_slot(slot)
signal attr_modifier_applied(attr: StringName, tooltip: String)
signal inv_changed()

signal spellbooks_changed(spellbook_name, status)
signal spellbook_spells_changed(spellbook_name, spell_dict, status)
signal spell_slots_changed(spellbook_name, level, status)
signal spell_slot_changed(spellbook_name, level, slot_index)

signal synch_item_added(item)
signal synch_item_removed(item)
signal synch_macro(macro_name, macro_dict, old_macro_name, remove)
signal synch_equip_slot(side, ind, move_ind, slot_dict, new, remove)
signal equip_slot_synched()

enum {SPELL_SLOT_DICT, SPELL_SLOT_CAST}
enum {SPELLBOOK_ADD, SPELLBOOK_REMOVE, CHANGE_SETTINGS}
enum {SPELL_ADD, SPELL_REMOVE, SPELL_CHANGE}
enum {SPELLSLOT_LEVEL_ADD, SPELLSLOT_LEVEL_REMOVE, SPELLSLOT_OTHER}

func get_token():
	emit_get_token_request_after_delay()
	token = await get_token_response
	
func emit_get_token_request_after_delay():
	if Globals.draw_layer == null:
		return
	if Globals.draw_layer.get_tree() != null:
		token = await Globals.draw_layer.get_tree().create_timer(0.01).timeout
		emit_signal("get_token_request")
		
#region Save and Load
#save character resource to file
func save(resolve_conflict: bool = false):
	#get full path to save
	var path = get_path_to_save()
	if resolve_conflict:
		var path_old = path
		var i = 0
		while DirAccess.dir_exists_absolute(path):
			i += 1
			path = path_old + "_" + str(i)
		if i != 0:
			name = name + "_" + str(i)
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	if not DirAccess.dir_exists_absolute(path):
		print("folder does not exist: " + path)
	#old save system - replaced by ConfigFile
	#var save = FileAccess.open(path + "/" + name, FileAccess.WRITE)
	#if save == null:
		#print("file open error - aborting")
		#print(error_string(FileAccess.get_open_error()))
		#return
	store_char_data(path + "/" + name)
	#save.close()
	
func store_char_data(save: String):
	var save_dict = {
		"name" = name,
		"attributes" = attributes,
		"global" = global,
		"singleton" = singleton,
		"save_as_token" = save_as_token,
		"player_character" = player_character,
		"char_sheet_path" = char_sheet_path,
		"token_shape" = token_shape,
		"token_size" = token_size,
		"token_scale" = token_scale,
		"token_outline_width" = token_outline_width,
		"token_outline_color" = token_outline_color,
		"token_outline_faction_color" = token_outline_faction_color,
		"token_texture" = token_texture,
		"token_texture_offset" = token_texture_offset,
		"token_texture_scale" = token_texture_scale,
		"items" = items,
		"equip_slots" = equip_slots,
		"bars" = bars,
		"attr_bubbles" = attr_bubbles,
		"macros" = macros,
		"spellbooks" = spellbooks
	}
	var config = ConfigFile.new()
	config.set_value("character_save", "save_data", save_dict)
	config.save(save)
	#save.store_line(JSON.stringify(save_dict))
	
func store_char_data_to_buffer():
	var file_path = Globals.base_dir_path + "/temp" #temp file for character - find availible file name
	var i = 1
	while FileAccess.file_exists(file_path):
		file_path = Globals.base_dir_path + "/temp_" + str(2)
		i += 1
	#var temp_charater_file = FileAccess.open(file_path, FileAccess.WRITE)
	store_char_data(file_path)
	#temp_charater_file.close()
	var buffer = FileAccess.get_file_as_bytes(file_path)
	DirAccess.remove_absolute(file_path)
	return buffer
	
func load_char(path: String, char_name: String, global: bool, tree_item: TreeItem):
	if not FileAccess.file_exists(path + "/" + char_name):
		return #no save to load
		
	self.name = char_name
	self.global = global
	self.tree_item = tree_item
	
	#load attributes from file - old system - replaced by ConfigFile - saves and loads data types
	#var save = FileAccess.open(path + "/" + char_name, FileAccess.READ)
	#if save == null:
		#print("file open error - aborting")
		#return
	#save.close()
	if not get_char_data(path + "/" + char_name):
		return
	tree_item.set_meta("character", self)
	
	connect("attr_updated", apply_modifiers_to_attr)
	connect("item_equipped", equip_item)
	connect("item_unequipped", unequip_item)
	
	load_equipped_items_from_equipment()
	load_attr_modifiers_from_equipment()
	print("attr mods: ", attribute_modifiers)
	
func get_char_data(save: String):
	
	var config = ConfigFile.new()
	var err = config.load(save)
	if err != OK:
		return false
	
	#json save - does not save property type (color, vector2, etc)
	#var json = JSON.new()
	#var error = json.parse(save.get_line())
	#if error == null or not json.data is Dictionary:
		#print("ERROR character save file is not a json dictionary!")
		#return
	#var save_dict: Dictionary = json.data
	
	var save_dict: Dictionary = config.get_value("character_save", "save_data")
	if save_dict == null:
		return false
	for key in save_dict.keys():
		self.set(key, save_dict[key])
		
	#binary serialize individual properties
	#name = save.get_var()
	#attributes = save.get_var()
	#global = save.get_var()
	#singleton = save.get_var()
	#save_as_token = save.get_var()
	#player_character = save.get_var()
	#char_sheet_path = save.get_var()
	#token_shape = save.get_var()
	#token_size = save.get_var()
	#token_scale = save.get_var()
	#token_outline_width = save.get_var()
	#token_outline_color = save.get_var()
	#token_outline_faction_color = save.get_var()
	#token_texture = save.get_var()
	#token_texture_offset = save.get_var()
	#token_texture_scale = save.get_var()
	#items = save.get_var()
	#equip_slots = save.get_var()
	#bars = save.get_var()
	#attr_bubbles = save.get_var()
	#macros = save.get_var()
	
	for macro in macros: #fill macros_in_bar
		if macros[macro]["in_bar"] == true:
			macros_in_bar[macro] = macros[macro]
	return true
	
func get_char_data_from_buffer(buffer: PackedByteArray):
	var file_path = Globals.base_dir_path + "/temp" #temp file for character - find availible file name
	var i = 1
	while FileAccess.file_exists(file_path):
		file_path = Globals.base_dir_path + "/temp_" + str(i)
		i += 1
	var temp_charater_file = FileAccess.open(file_path, FileAccess.WRITE_READ)
	temp_charater_file.store_buffer(buffer)
	temp_charater_file.seek(0)
	temp_charater_file.close()
	get_char_data(file_path)
	DirAccess.remove_absolute(file_path)
	
func get_path_to_save(include_name: bool = true):
	var base_path: String #character folder
	if global:
		base_path = Globals.base_dir_path + "/saves/Characters"
	else:
		base_path = Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/Characters"
	if not DirAccess.dir_exists_absolute(base_path):
		DirAccess.make_dir_recursive_absolute(base_path)
	var path: String #path to character inside character folder
	if include_name:
		path = name
	else:
		path = ""
	if tree_item == null:
		print("character tree_item is null !!!!")
		return base_path + "/" + path
	var item = tree_item.get_parent()
	var root = tree_item.get_tree().get_root()
	while item.get_parent() != root:
		path = item.get_text(0) + "/" + path
		item = item.get_parent()
	return base_path + "/" + path
	
func delete():
	var path = get_path_to_save(true)
	print(path)
	OS.move_to_trash(ProjectSettings.globalize_path(path)) #TODO might not work after project export: https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-move-to-trash
	
func load_attr_modifiers_from_equipment():
	for slot_array in equip_slots: #left, middle, right slot arrays
		for slot in slot_array: #slots
			if slot["item"] != null: #has item equipped
				equip_item(slot["item"], false)
	apply_modifiers()
	
func load_equipped_items_from_equipment():
	for slot_array in equip_slots: #left, middle, right slot arrays
		for slot in slot_array: #slots
			if slot["item"] != null: #has item equipped
				equipped_items.append(slot["item"])
#endregion

#region Equipment and modifiers
func equip_item(item, apply = true):
	#item["equip_slot_character"] = self #set equip_slot after loading
	item["equipped"] = true
	for modifier in item["attribute_modifiers"]:
		if not attribute_modifiers.has(modifier["attribute"]): #create array for modifiers of attribute if not exist
			attribute_modifiers[modifier["attribute"]] = []
		attribute_modifiers[modifier["attribute"]].append(modifier)
		if apply:
			apply_modifiers_to_attr(modifier["attribute"])
		
func unequip_item(item):
	for slot_arr in equip_slots: #find and remove item from slot
		var found = false #for skipping other arrays
		for slot in slot_arr:
			if is_same(slot["item"], item):
				slot["item"] = null #remove item from slot
				emit_signal("unequip_item_from_slot", slot) #removes item from equipment slot if visible
				found = true
				break
		if found:
			break
	for modifier in item["attribute_modifiers"]:
		var attr_mod_arr = attribute_modifiers[modifier["attribute"]]
		if attr_mod_arr == null:
			print("unequip - no attribute modifier by that name")
			continue
		for i in attr_mod_arr.size():
			if is_same(attr_mod_arr[i], modifier):
				attr_mod_arr.remove_at(i)
				break
	apply_modifiers() #recalculate and reapply modifiers
	#item.erase("equip_slot_character")

#resolve all attribute modifier conflicts and apply modifiers to attributes
func apply_modifiers():
	for attribute in attribute_modifiers:
		apply_modifiers_to_attr(attribute)

func apply_modifiers_to_attr(attribute, _remote = false):
	print("apply modifiers - ", attribute)
	if not attribute_modifiers.has(attribute):
		print("no modifier")
		if attributes.has(attribute):
			print(attributes[attribute][1], " --- ", attributes[attribute][0])
			attributes[attribute][1] = attributes[attribute][0]
			emit_signal("attr_modifier_applied", attribute, attributes[attribute][0])
		return
	var attr_arr = attribute_modifiers[attribute]
	if not attributes.has(attribute): #attr not found
		return
	var modifiers = {}
	#resolve all conflicts
	for modifier in attr_arr: #else apply modifiers to attribute
		print("apply modifiers - modifier: ", modifier)
		var type = modifier["type"]
		if modifiers.has(type): #already has type ("deflection, enchantment, etc.)
			var mode = modifier["mode"]
			if modifiers[type].has(mode): #already has mode (add, sub, etc.) - go by priority:
				if modifiers[type][mode]["priority"] == modifier["priority"]: #same priority - go by value
					if modifiers[type][mode]["value"].is_valid_float() and modifier["value"].is_valid_float(): #comparable numbers - get greater
						if modifiers[type][mode]["value"].to_float() < modifier["value"].to_float():
							modifiers[type][mode]["value"] = modifier["value"]
					else: #comparable strings - check if mode == ADD_STR
						if modifier["mode"] == 7: #correct mode - get greater string - for consistency
							if modifiers[type]["value"].to_float() < modifier["value"].to_float():
								modifiers[type]["value"] = modifier["value"]
						else: #not add string mode - do nothing
							continue
				elif modifiers[type][mode]["priority"] < modifier["priority"]: #same type and mode, different priority - overwrite if greater
					modifiers[type][mode]["priority"] = modifier["priority"]
					modifiers[type][mode]["value"] = modifier["value"]
			else: #same type, different mode - apply all modes
				var mod_dict_inner = {}
				mod_dict_inner["priority"] = modifier["priority"]
				mod_dict_inner["value"] = modifier["value"]
				modifiers[type][mode] = mod_dict_inner
		else: #first of type - create dict for modifier
			var mod_dict = {}
			var mod_dict_inner = {}
			mod_dict_inner["priority"] = modifier["priority"]
			mod_dict_inner["value"] = modifier["value"]
			mod_dict[modifier["mode"]] = mod_dict_inner
			modifiers[type] = mod_dict
			
	#apply modifiers to attribute
	#sort by priority
	var modifier_arr = [] #array of dicts {priority, value, mode, type}
	for modifier_type in modifiers:
		for modifier_mode in modifiers[modifier_type]:
			modifiers[modifier_type][modifier_mode]["mode"] = modifier_mode
			modifiers[modifier_type][modifier_mode]["type"] = modifier_type
			modifier_arr.append(modifiers[modifier_type][modifier_mode])
	modifier_arr.sort_custom(sort_by_priority)
	
	#apply modifiers to attribute
	var attr_val = attributes[attribute][0]
	var tooltip_text = attr_val
	for modifier in modifier_arr:
		var mode = modifier["mode"]
		if mode == 0: # ADD
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n + " + modifier["value"] + " : " + modifier["type"]
		elif mode == 1: # SUB
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n - " + modifier["value"] + " : " + modifier["type"]
		elif mode == 2: # SET
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n = " + modifier["value"] + " : " + modifier["type"]
		elif mode == 3: # MAX
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n MAX " + modifier["value"] + " : " + modifier["type"]
		elif mode == 4: # MIN
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n MIN " + modifier["value"] + " : " + modifier["type"]
		elif mode == 5: # MUL
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n * " + modifier["value"] + " : " + modifier["type"]
		elif mode == 6: # DIV
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n / " + modifier["value"] + " : " + modifier["type"]
		elif mode == 7: # ADD_STR
			attr_val = str(attr_val.to_float() + modifier["value"].to_float())
			tooltip_text += "\n +str " + modifier["value"] + " : " + modifier["type"]
	attributes[attribute][1] = attr_val
	print("emit tooltip changed")
	emit_signal("attr_modifier_applied", attribute, tooltip_text)

func sort_by_priority(a, b):
	return a["priority"] < b["priority"]
#endregion

#region Spell and SpellBooks
# ========================= SPELL AND SPELLBOOK SECTION ==============================
	
	
func add_new_spellbook(spellbook_name, remote = false):
	if spellbooks.has(spellbook_name):
		return false
	else:
		var spellbook_dict = {
			"spellbook_name": spellbook_name,
			"allow_spells_in_higher_slots": true,
			"spontaneous_spellcaster": false,
			"allowed_spell_categories_all": [], #spells must have all these categories to qualify
			"allowed_spell_categories_one": [], #spells must have one of these categories to qualify 
								#if both are specified then we take the intersect of them
								#example: all=[wizard, dnd] one=[evocation, illusion]
									# grabs all evocation and illusion spells from dnd wizard spells
									# ignore all spells that are not wizard and dnd and all not evocation/illusion spells
			"excluded_spell_categories": [], #currently not used TODO if needed
			"know_all_spells": false,
			"spells": [], #array of known spells for each spellbook
			"spell_slots": [] #array of spell_slots for each level - tracking of prepared spells and spells slots
		}
		spellbooks[spellbook_name] = spellbook_dict
		emit_signal("spellbooks_changed", spellbook_name, SPELLBOOK_ADD)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("add_new_spellbook", spellbook_name, true)
		return true

func remove_spellbook(spellbook_name, remote = false):
	if not spellbooks.has(spellbook_name):
		return false
	else:
		spellbooks.erase(spellbook_name)
		emit_signal("spellbooks_changed", spellbook_name, SPELLBOOK_REMOVE)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("remove_spellbook", spellbook_name, true)
		return true
		
func add_spell_to_spellbook(spell_dict, spellbook_name, remote = false):
	if spell_dict != null and spellbooks.has(spellbook_name):
		spellbooks[spellbook_name]["spells"].append(spell_dict)
		emit_signal("spellbook_spells_changed", spellbook_name, spell_dict, SPELL_ADD)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("add_spell_to_spellbook", spell_dict, spellbook_name, true)
		
func remove_spell_from_spellbook(spell_dict, spellbook_name, remote = false):
	if spellbooks.has(spellbook_name):
		spellbooks[spellbook_name]["spells"].erase(spell_dict)
		emit_signal("spellbook_spells_changed", spellbook_name, spell_dict, SPELL_REMOVE)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("remove_spell_from_spellbook", spell_dict, spellbook_name, true)

func add_spell_to_prepared(spell, spellbook_name, spell_level = null, spell_slot_index = null, remote = false):
	#check if data is fine
	if spell == null:
		print("spell is null !!!")
		return
	if not spellbooks.has(spellbook_name):
		print("no spellbook: ", spellbook_name, " !!!")
		return
	if not spellbooks[spellbook_name].has("spell_slots"):
		spellbooks[spellbook_name]["spell_slots"]=[]
		print("no spellslots !!!")
		return #no slots
	if spell_level == null:
		spell_level = spell["spell_level"]
	if spell["spell_level"] < spell_level:
		return
	elif spell["spell_level"] > spell_level:
		if not spellbooks[spellbook_name]["allow_spells_in_higher_slots"]:
			return
	if spellbooks[spellbook_name]["spell_slots"].size() < spell_level-1:
		print("no spellslots for level: " + spell_level-1 + " !!!")
		return
	#add spell to prepared 
	if spell_slot_index == null: #add spell to the firts free slot for the spell level
		var slot_index = 0
		for spell_slot in spellbooks[spellbook_name]["spell_slots"][spell_level-1]:
			if spell_slot[SPELL_SLOT_DICT] == null: #free slot found
				spell_slot[SPELL_SLOT_DICT] = spell
				self.emit_signal("spell_slot_changed", spellbook_name, spell_level, slot_index)
				break
			slot_index += 1
	else: #specific spell slot - replace spell
		spellbooks[spellbook_name]["spell_slots"][spell_level-1][spell_slot_index][SPELL_SLOT_DICT] = spell
		self.emit_signal("spell_slot_changed", spellbook_name, spell_level, spell_slot_index)
	if not remote: #sync to other peers
		call_character_function_on_remote_peers_through_token("add_spell_to_prepared", spell, spellbook_name, spell_level, spell_slot_index, true)

func add_spell_slot_level(spellbook_name, remote = false):
	if spellbooks.has(spellbook_name):
		if not spellbooks[spellbook_name].has("spell_slots"):
			spellbooks[spellbook_name]["spell_slots"] = []
		spellbooks[spellbook_name]["spell_slots"].append([])
		print("adding spellslot one")
		self.emit_signal("spell_slots_changed", spellbook_name, spellbooks[spellbook_name]["spell_slots"].size(), SPELLSLOT_LEVEL_ADD)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("add_spell_slot_level", spellbook_name, true)

func remove_spell_slot_level(spellbook_name, remote = false):
	if spellbooks.has(spellbook_name):
		if not spellbooks[spellbook_name].has("spell_slots"):
			spellbooks[spellbook_name]["spell_slots"] = []
		spellbooks[spellbook_name]["spell_slots"].pop_back()
		print(spellbooks[spellbook_name]["spell_slots"])
		self.emit_signal("spell_slots_changed", spellbook_name, spellbooks[spellbook_name]["spell_slots"].size() + 1, SPELLSLOT_LEVEL_REMOVE)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("remove_spell_slot_level", spellbook_name, true)

func add_spell_slot(spellbook_name, spell_slot_level, remote = false):
	if spellbooks.has(spellbook_name):
		if not spellbooks[spellbook_name].has("spell_slots"):
			spellbooks[spellbook_name]["spell_slots"] = []
			return #no spell slot levels to add spell_slot to?
		if spellbooks[spellbook_name]["spell_slots"].size() < spell_slot_level:
			return #no spell slot level to add spell_slot to?
		spellbooks[spellbook_name]["spell_slots"][spell_slot_level-1].append([null, false]) # [spell_dict, already_cast_bool]
		self.emit_signal("spell_slots_changed", spellbook_name, spell_slot_level, SPELLSLOT_OTHER)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("add_spell_slot", spellbook_name, spell_slot_level, true)
		
func remove_spell_slot(spellbook_name, spell_slot_level, remote = false):
	if spellbooks.has(spellbook_name):
		if not spellbooks[spellbook_name].has("spell_slots"):
			spellbooks[spellbook_name]["spell_slots"] = []
			return #no spell slot levels to add spell_slot to?
		if spellbooks[spellbook_name]["spell_slots"].size() < spell_slot_level:
			return #no spell slot level to add spell_slot to?
		spellbooks[spellbook_name]["spell_slots"][spell_slot_level-1].pop_back()
		self.emit_signal("spell_slots_changed", spellbook_name, spell_slot_level, SPELLSLOT_OTHER)
		if not remote: #sync to other peers
			call_character_function_on_remote_peers_through_token("remove_spell_slot", spellbook_name, spell_slot_level, true)
		
func cast_spell (spellbook_name = null, spell_level = null, spell_slot_index = null, spell_dict = null):
	print("casting spell")
	if spellbook_name != null and spell_level != null and spell_slot_index != null: #cast spell from spell_slot_arr
		if spellbooks.has(spellbook_name):
			if spellbooks[spellbook_name].has("spell_slots"):
				if spellbooks[spellbook_name]["spell_slots"].size() >= spell_level:
					if spellbooks[spellbook_name]["spell_slots"][spell_level-1].size() > spell_slot_index:
						var spell_slot_arr = spellbooks[spellbook_name]["spell_slots"][spell_level-1][spell_slot_index]
						if spell_slot_arr[SPELL_SLOT_CAST] == false and spell_slot_arr[SPELL_SLOT_DICT] != null:
							spell_slot_arr[SPELL_SLOT_CAST] = true
							self.emit_signal("spell_slot_changed", spellbook_name, spell_level, spell_slot_index)
							Globals.roll_panel.cast_spell(spell_slot_arr[SPELL_SLOT_DICT], self)
							print("spell cast from spell_slot")
							#sync slot usage to other peers
							call_character_function_on_remote_peers_through_token("mark_spell_as_cast_or_not_cast", spellbook_name, spell_level, spell_slot_index, true, true)
							return
	elif spellbook_name != null and spell_dict != null: #cast from spellcard
		if spellbooks.has(spellbook_name):
			if spellbooks[spellbook_name]["spontaneous_spellcaster"]: # spontaneous spellcaster try to find free spell_slot
				if spellbooks[spellbook_name].has("spell_slots"):
					if spellbooks[spellbook_name]["spell_slots"].size() >= spell_dict["spell_level"]:
						spell_level = spell_dict["spell_level"]
						var spell_slot_counter = 0
						for spell_slot_arr in spellbooks[spellbook_name]["spell_slots"][spell_level - 1]:
							if not spell_slot_arr[SPELL_SLOT_CAST]:
								spell_slot_arr[SPELL_SLOT_CAST] = true
								self.emit_signal("spell_slot_changed", spellbook_name, spell_level, spell_slot_counter)
								Globals.roll_panel.cast_spell(spell_dict, self)
								print("spell cast as spontaneous")
								#sync slot usage to other peers
								call_character_function_on_remote_peers_through_token("mark_spell_as_cast_or_not_cast", spellbook_name, spell_level, spell_slot_counter, true, true)
								return
							spell_slot_counter += 1
						#no spellslot of said level found - check if allowed to cast in higher level slots
						if spellbooks[spellbook_name]["allow_spells_in_higher_slots"]:
							for i in range(spell_level, spellbooks[spellbook_name]["spell_slots"].size()):
								spell_slot_counter = 0
								for spell_slot_arr in spellbooks[spellbook_name]["spell_slots"][i]:
									if not spell_slot_arr[SPELL_SLOT_CAST]:
										spell_slot_arr[SPELL_SLOT_CAST] = true
										self.emit_signal("spell_slot_changed", spellbook_name, i, spell_slot_counter)
										Globals.roll_panel.cast_spell(spell_dict, self)
										print("spell cast as spontaneous from higher level")
										#sync slot usage to other peers
										call_character_function_on_remote_peers_through_token("mark_spell_as_cast_or_not_cast", spellbook_name, i, spell_slot_counter, true, true)
										return
									spell_slot_counter += 1
									
	if spell_dict == null:
		return
	#no good slot found
	Globals.roll_panel.cast_spell(spell_dict, self, false)
	
#recover all spell_slots for spell_book
func rest_spells(spellbook_name, remote = false):
	if spellbooks.has(spellbook_name):
		if spellbooks[spellbook_name].has("spell_slots"):
			var i = 1
			for spell_slot_level in spellbooks[spellbook_name]["spell_slots"]:
				var j = 0
				for spell_arr in spell_slot_level:
					spell_arr[SPELL_SLOT_CAST] = false
					self.emit_signal("spell_slot_changed", spellbook_name, i, j)
					j += 1
				i += 1
			if not remote: #sync to other peers
				call_character_function_on_remote_peers_through_token("rest_spells", spellbook_name, true)
		
func remove_spell_from_spellslot(spellbook_name, spell_level, spell_slot_index, remote = false):
	if spellbook_name != null and spell_level != null and spell_slot_index != null:
		if spellbooks.has(spellbook_name):
			if spellbooks[spellbook_name].has("spell_slots"):
				if spellbooks[spellbook_name]["spell_slots"].size() >= spell_level:
					if spellbooks[spellbook_name]["spell_slots"][spell_level-1].size() > spell_slot_index:
						var spell_slot_arr = spellbooks[spellbook_name]["spell_slots"][spell_level-1][spell_slot_index]
						spell_slot_arr[SPELL_SLOT_DICT] = null
						self.emit_signal("spell_slot_changed", spellbook_name, spell_level, spell_slot_index)
						if not remote: #sync to other peers
							call_character_function_on_remote_peers_through_token("remove_spell_from_spellslot", spellbook_name, spell_level, spell_slot_index, true)

func mark_spell_as_cast_or_not_cast(spellbook_name, spell_level, spell_slot_index, value = null, remote = false):
	if spellbook_name != null and spell_level != null and spell_slot_index != null:
		if spellbooks.has(spellbook_name):
			if spellbooks[spellbook_name].has("spell_slots"):
				if spellbooks[spellbook_name]["spell_slots"].size() >= spell_level:
					if spellbooks[spellbook_name]["spell_slots"][spell_level-1].size() > spell_slot_index:
						var spell_slot_arr = spellbooks[spellbook_name]["spell_slots"][spell_level-1][spell_slot_index]
						if value == null:
							spell_slot_arr[SPELL_SLOT_CAST] = not spell_slot_arr[SPELL_SLOT_CAST]
						else:
							spell_slot_arr[SPELL_SLOT_CAST] = value
						self.emit_signal("spell_slot_changed", spellbook_name, spell_level, spell_slot_index)
						if not remote: #sync to other peers
							call_character_function_on_remote_peers_through_token("mark_spell_as_cast_or_not_cast", spellbook_name, spell_level, spell_slot_index, spell_slot_arr[SPELL_SLOT_CAST], true)
#endregion

func call_character_function_on_remote_peers_through_token(func_name, ...args):
	if token != null:
		token.call_character_function_on_remote_peers.rpc(func_name, args)
