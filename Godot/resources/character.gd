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

var tree_item: TreeItem

signal token_changed()
signal bars_changed()
signal attr_bubbles_changed()
signal attr_updated(attr: StringName)
signal macro_bar_changed(macro, macro2)
signal equip_slots_changed(equip_slot_dict, side: int, new: bool)
signal equipped_item_changed(item)
signal item_equipped(item)
signal item_unequipped(item)
signal unequip_item_from_slot(slot)
signal attr_modifier_applied(attr: StringName, tooltip: String)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

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
	var save = FileAccess.open(path + "/" + name, FileAccess.WRITE)
	if save == null:
		print("file open error - aborting")
		print(error_string(FileAccess.get_open_error()))
		return
	store_char_data(save)
	save.close()
	
func store_char_data(save: FileAccess):
	save.store_var(name)
	save.store_var(attributes)
	save.store_var(global)
	save.store_var(singleton)
	save.store_var(save_as_token)
	save.store_var(token_shape)
	save.store_var(token_size)
	save.store_var(token_scale)
	save.store_var(token_outline_width)
	save.store_var(token_outline_color)
	save.store_var(token_outline_faction_color)
	save.store_var(token_texture)
	save.store_var(token_texture_offset)
	save.store_var(token_texture_scale)
	print("items: ", items)
	save.store_var(items)
	print("equip_slots: ", equip_slots)
	save.store_var(equip_slots)
	print("bars: ", bars)
	save.store_var(bars)
	save.store_var(attr_bubbles)
	save.store_var(macros)
	
func load_char(path: String, char_name: String, global: bool, tree_item: TreeItem):
	if not FileAccess.file_exists(path + "/" + char_name):
		return #no save to load
		
	self.name = char_name
	self.global = global
	self.tree_item = tree_item
	#load attributes from file
	var save = FileAccess.open(path + "/" + char_name, FileAccess.READ)
	if save == null:
		print("file open error - aborting")
		return
	get_char_data(save)
	save.close()
	
	tree_item.set_meta("character", self)
	
	connect("attr_updated", apply_modifiers_to_attr)
	connect("item_equipped", equip_item)
	connect("item_unequipped", unequip_item)
	
	load_equipped_items_from_equipment()
	load_attr_modifiers_from_equipment()
	print("attr mods: ", attribute_modifiers)
	
func get_char_data(save: FileAccess):
	name = save.get_var()
	attributes = save.get_var()
	#TODO REMOVE fix attributes
	for attr in attributes:
		if attributes[attr] is String:
			attributes[attr] = [attributes[attr], attributes[attr]]
	global = save.get_var()
	singleton = save.get_var()
	save_as_token = save.get_var()
	token_shape = save.get_var()
	token_size = save.get_var()
	token_scale = save.get_var()
	token_outline_width = save.get_var()
	token_outline_color = save.get_var()
	token_outline_faction_color = save.get_var()
	token_texture = save.get_var()
	token_texture_offset = save.get_var()
	token_texture_scale = save.get_var()
	items = save.get_var()
	equip_slots = save.get_var()
	bars = save.get_var()
	attr_bubbles = save.get_var()
	macros = save.get_var()
	for macro in macros: #fill macros_in_bar
		if macros[macro]["in_bar"] == true:
			macros_in_bar[macro] = macros[macro]
	
	
func get_path_to_save(include_name: bool = true):
	var base_path: String #character folder
	if global:
		base_path = "res://saves/Characters"
	else:
		base_path = "res://saves/Campaigns/" + Globals.campaign.campaign_name + "/Characters"
	if not DirAccess.dir_exists_absolute(base_path):
		DirAccess.make_dir_recursive_absolute(base_path)
	var path: String #path to character inside character folder
	if include_name:
		path = name
	else:
		path = ""
	var item = tree_item.get_parent()
	var root = tree_item.get_tree().get_root()
	while item.get_parent() != root:
		path = item.get_text(0) + "/" + path
		item = item.get_parent()
	return base_path + "/" + path
	
func delete():
	var path = get_path_to_save(true)
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

func apply_modifiers_to_attr(attribute):
	print("apply modifiers - ", attribute)
	if not attribute_modifiers.has(attribute):
		if attributes.has(attribute):
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
