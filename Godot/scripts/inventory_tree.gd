extends Tree

var categories = {}
var items = []
var equipped_items = []
var character = null
 
# Called when the node enters the scene tree for the first time.
func _ready():
	#set column titles
	set_column_title(0, "Equipped")
	set_column_expand(0, false)
	set_column_title(1, "Item Name")
	set_column_expand(1, true)
	set_column_expand_ratio(1, 2)
	set_column_title(2, "Description")
	set_column_expand(2, true)
	set_column_title(3, "Count")
	set_column_expand(3, false)
	set_column_title(4, "Weight")
	set_column_expand(4, false)
	set_column_title(5, "Total Weight")
	set_column_expand(5, false)
	
	#create root
	hide_root = false
	var root = create_item(null)
	root.disable_folding = true
	root.set_text(1, "Total")
	root.set_cell_mode(5, TreeItem.CELL_MODE_RANGE)
	root.set_range_config(5, 0, 99999999, 1)
	root.set_range(5, 0)
	
	#get inventory items
	var char_sheet = $"../../../../.."
	if char_sheet != null and "character" in char_sheet: #inventory in character sheet
		character = char_sheet.character
		items = character.items
		equipped_items = character.equipped_items
	else:
		pass #inventory in container - manually set after instantiate
	#items.append_array([
	#{
		#"category": "weapon",
		#"name": "sword",
		#"icon": "",
		#"weight": 3,
		#"count": 1,
		#"description": "a sharp stick",
		#"attributes": {},
		#"attribute_modifiers": {},
		#"macros": {}
	#},
	#{
		#"category": "armor",
		#"name": "chainmail",
		#"icon": "",
		#"weight": 25,
		#"count": 1,
		#"description": "armor made of interlocking rings",
		#"attributes": {},
		#"attribute_modifiers": {},
		#"macros": {}
	#}
	#])
	
	load_inventory(character)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_inventory(character):
	print("eq items: ", equipped_items)
	for item in equipped_items:
		add_item_treeitem(item, false, character)
	print("items: ", items)
	for item in items:
		add_item_treeitem(item, false)
		
			
#creates treeitem in tree representing item
func add_item_treeitem(item_dict, add_to_inventory = true, character = null):
	print("add item start: ", items)
	var category = item_dict["category"]
	if not categories.has(category): #create category item
		var category_item = create_item(null)
		category_item.set_text(1, category)
		category_item.set_cell_mode(5, TreeItem.CELL_MODE_RANGE)
		category_item.set_range_config(5, 0, 99999999, 1)
		category_item.set_range(5, 0)
		categories[category] = category_item
	
	#create item in category
	var new_item = create_item(categories[category])
	new_item.set_meta("item_dict", item_dict)
	if item_dict["equipped"]: #set inventory for deleting
		new_item.set_meta("item_char", character)
		new_item.set_meta("inventory", equipped_items)
	else:
		new_item.set_meta("inventory", items)
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_item.set_editable(0, false)
	new_item.set_checked(0, item_dict["equipped"])
	var icon = load(item_dict["icon"])
	if icon != null:
		new_item.set_icon(1, icon)
	new_item.set_text(1, item_dict["name"])
	new_item.set_text(2, item_dict["description"])
	new_item.set_cell_mode(3, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(3, 0, 999999, 1)
	new_item.set_range(3, item_dict["count"])
	new_item.set_editable(3, true)
	new_item.set_cell_mode(4, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(4, 0, 999999, 1)
	new_item.set_range(4, item_dict["weight"])
	new_item.set_cell_mode(5, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(5, 0, 99999999, 1)
	new_item.set_range(5, new_item.get_range(3) * new_item.get_range(4))
	change_weight(new_item, new_item.get_range(5))
	
	if add_to_inventory:
		if item_dict["equipped"]: #equipped item
			equipped_items.append(item_dict)
		else:
			items.append(item_dict)
	print("add item end: ", items)
	return new_item
		
#changes total weight of treeitem, it's category and Total
func change_weight(tree_item: TreeItem, weight_diff):
	tree_item.set_range(5, tree_item.get_range(3) * tree_item.get_range(4))
	var parent_item = tree_item.get_parent() #category item
	parent_item.set_range(5, parent_item.get_range(5) + weight_diff)
	parent_item = parent_item.get_parent() #total item
	parent_item.set_range(5, parent_item.get_range(5) + weight_diff)
	
#sets all Total Weight ranges
func update_total_weight(change_item_weights = false):
	var root = get_root()
	var total_weight = 0
	for category in root.get_children():
		var category_weight = 0
		for item in category.get_children():
			if change_item_weights:
				item.set_range(5, item.get_range(3) * item.get_range(4))
			category_weight += item.get_range(5)
		category.set_range(5, category_weight)
		total_weight += category_weight
	
func _get_drag_data(_item_position):
	#place drag and drop layer on top - in case of dragging to map
	Globals.drag_drop_canvas_layer.layer = 128
	
	set_drop_mode_flags(DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM)
	var selected = get_selected()
	if not selected:
		return
	var preview = Label.new()
	preview.text = selected.get_text(1)
	set_drag_preview(preview)
	return selected
	
func _can_drop_data(at_position, data):
	print(data, data.has_meta("item_dict"))
	return data.has_meta("item_dict")
	
func _drop_data(at_position, data):
	var item_dict = data.get_meta("item_dict")
	var new_item_dict = item_dict.duplicate(true)
	new_item_dict["equipped"] = false
	add_item_treeitem(new_item_dict)
	if data.has_meta("inventory"): #dragging from inventory - remove from old
		var inventory = data.get_meta("inventory")
		if item_dict["equipped"]: #unequip
			var char = data.get_meta("item_char")
			char.unequip_item(item_dict)
		for i in inventory.size():
			if is_same(inventory[i], item_dict): #remove from inventory array
				inventory.remove_at(i)
				break
		data.free() #remove treeitem in old inventory
	Globals.drag_drop_canvas_layer.layer = -1

#returns treeitem of searched item
func get_item_treeitem(item):
	for category in categories:
		for tree_item in categories[category].get_children():
			if is_same(item, tree_item.get_meta("item_dict")):
				return tree_item
	return null
