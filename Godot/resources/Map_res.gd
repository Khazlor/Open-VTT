#Author: Vladimír Horák
#Desc:
#Resource for saving map data

class_name Map_res
extends Resource

var token_comp = preload("res://components/token.tscn") #token component

@export var map_name = "Map Name"
@export var map_desc = "Description"
@export var background_color = Color.DARK_GRAY
#grid settings
@export var grid_enable = true
@export var grid_color = Color(0,0,0,0.7)
@export var grid_thickness = 0.01
@export var grid_size = 70
@export var unit_size = 5
@export var unit = "ft"
#darkness settings
@export var darkness_enable = false
@export var darkness_color = Color.BLACK
@export var DM_darkness_color = Color.DIM_GRAY
#fov settings
@export var fov_enable = false
@export var fov_opacity = 0.3
@export var fov_color = Color.BLACK
#preview
@export var image: String = Globals.base_dir_path + "/images/Placeholder-1479066.png"
#saved layers
#@export var saved_layers: PackedScene = null
var tokens = []
var singleton_token_chars = {}
#var token_paths = []
#var token_indexes = []

#func save(packed_layers: PackedScene):
	#saved_layers = packed_layers
	#if saved_layers == null:
		#print("saved layers is null")
		#return
	#save_map()
#
##saving using store_var(obj, true) currently broken in godot for objects with attached script with class_name as per:
##https://github.com/godotengine/godot/issues/68666
##stored var includes attached script as plain text -> leads to multiple scripts with same class_name -> parse error
##work around - saving tokens separately -> will no longer be needed if issue is fixed
#func save_map():
	#var map_save = FileAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.WRITE)
	#if map_save == null:
		#print("file open error - aborting")
		#return
	##save map data
	#map_save.store_var(saved_layers, true)
	#map_save.store_var(map_desc)
	#map_save.store_var(grid_size)
	#map_save.store_var(image)
	##save tokens - separately - more above
	#map_save.store_var(tokens.size())
	#for token in tokens:
		#save_token(map_save, token)
	#map_save.close()
	

func save_map(layers: Node2D):
	var map_save = FileAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.WRITE)
	if map_save == null:
		print("file open error - aborting")
		return
	
	#save map meta data
	map_save.store_var(map_desc)
	map_save.store_var(background_color)
	
	if layers != null:
		image = Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name + ".jpg"
		var img = Globals.lobby.get_viewport().get_texture().get_image()
		var min = min(img.get_height(),img.get_width())
		if min == img.get_height():
			img.blit_rect(img, Rect2i((img.get_width()-min)/2, 0, min, min), Vector2i(0,0))
		else:
			img.blit_rect(img, Rect2i(0, (img.get_height()-min)/2, min, min), Vector2i(0,0))
		img.crop(min, min)
		img.resize(256, 256, Image.INTERPOLATE_BILINEAR)
		img.save_jpg(image)
		
	map_save.store_var(image)
	
	map_save.store_var(grid_enable)
	map_save.store_var(grid_color)
	map_save.store_var(grid_thickness)
	map_save.store_var(grid_size)
	map_save.store_var(unit_size)
	map_save.store_var(unit)
	#darkness settings
	map_save.store_var(darkness_enable)
	map_save.store_var(darkness_color)
	map_save.store_var(DM_darkness_color)
	#fov settings
	map_save.store_var(fov_enable)
	map_save.store_var(fov_opacity)
	map_save.store_var(fov_color)
	
	#save map data
	if layers != null:
		for layer in layers.get_children():
			save_data_for_self_and_children(layer, map_save)
	print("save ", map_save.get_length())
	map_save.close()


func save_data_for_self_and_children(node, file: FileAccess):
	if not node.has_meta("type"):
		return
	var object_data_arr = []
	#var is_token = false
	var type = node.get_meta("type")
	print("save object - ", type)
	if type == "rect": #object is rectangle - panel
		var style_arr = []
		var style = node.get_theme_stylebox("panel")
		print(style)
		if style is StyleBoxFlat:
			style_arr = [style.bg_color, style.border_color, style.border_width_left]
		elif style is StyleBoxTexture:
			if style.texture != null:
				style_arr = [style.texture.get_meta("image_path")]
			else:
				style_arr = [Globals.colorBack, Globals.colorLines, Globals.lineWidth]
		object_data_arr.append(["rect", node.position, node.size, node.scale, node.rotation, style_arr, node.name])
	elif type == "line":
		var line
		for child in node.get_children():
			if child is Line2D:
				line = child
				break
		if line == null:
			print("saving line - not line - need fix") 
			return
		var style_arr = [line.points, line.default_color, line.width]
		object_data_arr.append(["line", node.position, node.size, node.scale, node.rotation, style_arr, node.name])
	elif type == "circle":
		print("circle")
		var style_arr = [node.line_color, node.back_color, node.line_width]
		object_data_arr.append(["circle", node.position, node.size, node.scale, node.rotation, style_arr, node.name])
	elif type == "text":
		var style_arr = [node.get_theme_font("font"), node.get_theme_font_size("font_size"), node.get_theme_color("font_color")]
		object_data_arr.append(["text", node.position, node.size, node.scale, node.rotation, node.text, node.name, style_arr])
	elif type == "token":
		var token = node.token_polygon
		if token.character.save_as_token:
			object_data_arr.append(["token", token.position, token.size, token.scale, token.rotation, token.character.store_char_data_to_buffer(), node.name])
		elif token.character.tree_item != null:
			object_data_arr.append(["token-s", token.position, token.size, token.scale, token.rotation, Globals.char_tree.get_char_path(token.character.tree_item), node.name, token.character.store_char_data_to_buffer()])
			token.character.save()
		else: #char no longer in tree - save as token
			object_data_arr.append(["token", token.position, token.size, token.scale, token.rotation, token.character.store_char_data_to_buffer(), node.name])
		node = token
	elif type == "container":
		var inventory = node.get_meta("inventory")
		object_data_arr.append(["container", node.position, node.size, node.scale, node.rotation, inventory, node.name])

	#light and shadow can be be on any object
	if node.has_meta("light"):
		var light: PointLight2D = Globals.draw_comp.get_object_light(node)
		var remote: RemoteTransform2D = Globals.draw_comp.get_object_light_remote(node)
		var light_arr = ["light", light.color, light.energy, light.texture.get_height(), light.texture_scale, remote.position, light.name, remote.name]
		object_data_arr.append(light_arr)
	if node.has_meta("shadow"):
		var occluder: LightOccluder2D = Globals.draw_comp.get_object_shadow(node)
		var occluder_arr = ["shadow", occluder.occluder.polygon, occluder.occluder.cull_mode, occluder.name]
		object_data_arr.append(occluder_arr)
		
	if not object_data_arr.is_empty():
		print("store - ",object_data_arr)
		file.store_var(object_data_arr)
		#if is_token:
			#save_token(file, node)
		return
		
	if type == "layer": #name, visibility, GM, light layers
		var name = node.get_meta("item_name")
		print("save layer: ", name)
		var visibility = node.get_meta("visibility")
		var DM = node.get_meta("DM")
		var player_layer = node.get_meta("player_layer")
		object_data_arr.append(["layer", name, visibility, DM, player_layer, node.light_mask, node.name])
		file.store_var(object_data_arr)
		print("store - ",object_data_arr)
		#save layer children
		for child in node.get_children():
			save_data_for_self_and_children(child, file)
		file.store_var(["child_end"])
		print("store - ","child_end")


func load_map(map_name, load_map_data = true, map_save = null):
	self.map_name = map_name
	if map_save == null: #save not opened - open save
		if not FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name):
			return #no save to load
		map_save = FileAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.READ)
		if map_save == null:
			print("file open error - aborting")
			return
	#load map metadata
	print("loading map")
	map_desc = map_save.get_var()
	background_color = map_save.get_var()
	image = map_save.get_var()
	
	grid_enable = map_save.get_var()
	grid_color = map_save.get_var()
	grid_thickness = map_save.get_var()
	grid_size = map_save.get_var()
	unit_size = map_save.get_var()
	unit = map_save.get_var()

	darkness_enable = map_save.get_var()
	darkness_color = map_save.get_var()
	DM_darkness_color = map_save.get_var()

	fov_enable = map_save.get_var()
	fov_opacity = map_save.get_var()
	fov_color = map_save.get_var()
	
	#load map
	if load_map_data:
		tokens.clear()
		while map_save.get_position() < map_save.get_length(): #read all data
			load_data_for_self_and_children(map_save)
		
	map_save.close()
	return 
	

func load_data_for_self_and_children(file: FileAccess):
	var object_data_arr = file.get_var()
	print("load object - ", object_data_arr)
	var node = null
	
	if object_data_arr[0][0] == "rect": #object is rectangle - panel
		var style
		if object_data_arr[0][5].size() == 1: #texture:
			print("texture rect loading")
			style = StyleBoxTexture.new()
			var texture = Globals.load_texture(object_data_arr[0][5][0])
			print("texture: texture")
			if texture != null:
				texture.set_meta("image_path", object_data_arr[0][5][0])
				style.texture = texture
		elif object_data_arr[0][5].size() == 3: #flat
			style = StyleBoxFlat.new()
			style.bg_color = object_data_arr[0][5][0]
			style.border_color = object_data_arr[0][5][1]
			style.set_border_width_all(object_data_arr[0][5][2])
		node = Panel.new()
		node.position = object_data_arr[0][1]
		node.size = object_data_arr[0][2]
		node.scale = object_data_arr[0][3]
		node.rotation = object_data_arr[0][4]
		node.set_meta("type", "rect")
		node.add_theme_stylebox_override("panel", style)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Globals.draw_layer.add_child(node)
		node.name = object_data_arr[0][6]
	elif object_data_arr[0][0] == "line":
		node = ColorRect.new()
		node.color = Color(0,0,0,0)
		node.position = object_data_arr[0][1]
		node.size = object_data_arr[0][2]
		node.scale = object_data_arr[0][3]
		node.rotation = object_data_arr[0][4]
		node.set_meta("type", "line")
		node.set_meta("polygon", true)
		var line = Line2D.new()
		line.points = object_data_arr[0][5][0]
		line.default_color = object_data_arr[0][5][1]
		line.width = object_data_arr[0][5][2]
		line.position = -node.position
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(line)
		Globals.draw_layer.add_child(node)
		node.name = object_data_arr[0][6]
	elif object_data_arr[0][0] == "circle":
		node = CustomEllipse.new()
		node.position = object_data_arr[0][1]
		node.size = object_data_arr[0][2]
		node.scale = object_data_arr[0][3]
		node.rotation = object_data_arr[0][4]
		node.line_color = object_data_arr[0][5][0]
		node.back_color = object_data_arr[0][5][1]
		node.line_width = object_data_arr[0][5][2]
		node.set_meta("type", "circle")
		node.set_meta("polygon", true)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Globals.draw_layer.add_child(node)
		node.name = object_data_arr[0][6]
	elif object_data_arr[0][0] == "text":
		node = Label.new()
		node.position = object_data_arr[0][1]
		node.size = object_data_arr[0][2]
		node.scale = object_data_arr[0][3]
		node.rotation = object_data_arr[0][4]
		node.text = object_data_arr[0][5]
		node.set_meta("type", "text")
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Globals.draw_layer.add_child(node)
		node.name = object_data_arr[0][6]
		node.add_theme_font_override("font", object_data_arr[0][7][0])
		node.add_theme_font_size_override("font_size", object_data_arr[0][7][1])
		node.add_theme_color_override("font_color", object_data_arr[0][7][2])
	elif object_data_arr[0][0] == "token" or object_data_arr[0][0] == "token-s":
		print("loading token")
		#var token = token_comp.instantiate()
		#node = load_token(file)
		node = token_comp.instantiate()
		node.character = Character.new()
		var token_polygon = node.get_node("TokenPolygon")
		node.token_polygon = token_polygon
		token_polygon.position = object_data_arr[0][1]
		token_polygon.size = object_data_arr[0][2]
		token_polygon.scale = object_data_arr[0][3]
		token_polygon.rotation = object_data_arr[0][4]
		if object_data_arr[0][0] == "token-s": #singleton on server
			if Globals.lobby.check_is_server():
				var tree_item = Globals.char_tree.get_char_at_path(object_data_arr[0][5])
				if tree_item == null: #character no longer in tree
					node.character.get_char_data_from_buffer(object_data_arr[0][7]) #get node backup
				else:
					node.character = tree_item.get_meta("character")
			else: #client - currently does not have character tree
				var key = str(object_data_arr[0][5])
				if singleton_token_chars.has(key):
					node.character = singleton_token_chars[key]
				else:
					node.character.get_char_data_from_buffer(object_data_arr[0][7])
					node.character.singleton_dict_key = key
					singleton_token_chars[key] = node.character
		else: #token - not singleton
			node.character.get_char_data_from_buffer(object_data_arr[0][5])
		node.set_meta("type", "token")
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Globals.draw_layer.add_child(node)
		node.name = object_data_arr[0][6]
		Globals.new_map.add_token(node)
	elif object_data_arr[0][0] == "container":
		print("loading container")
		node = Panel.new() 
		node.position = object_data_arr[0][1]
		node.size = object_data_arr[0][2]
		node.scale = object_data_arr[0][3]
		node.rotation = object_data_arr[0][4]
		node.set_meta("inventory", object_data_arr[0][5])
		node.set_meta("type", "container")
		node.add_user_signal("inv_changed")
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Globals.draw_layer.add_child(node)
		node.name = object_data_arr[0][6]
	
	elif object_data_arr[0][0] == "layer": #name, visibility, GM, light layers
		node = Node2D.new()
		node.set_meta("type", "layer")
		node.set_meta("item_name", object_data_arr[0][1])
		print("load layer: ", object_data_arr[0][1])
		node.set_meta("visibility", object_data_arr[0][2])
		node.set_meta("DM", object_data_arr[0][3])
		node.set_meta("player_layer", object_data_arr[0][4])
		node.light_mask = object_data_arr[0][5]
		Globals.draw_layer.add_child(node)
		node.name = object_data_arr[0][6]
		Globals.draw_layer = node
		if not object_data_arr[0][2] or not Globals.lobby.check_is_server() and object_data_arr[0][3]: #not visible or not server and is DM layer - hide layer
			node.visible = false

	elif object_data_arr[0] == "child_end": #put at end of children list
		Globals.draw_layer = Globals.draw_layer.get_parent()
		
	#load light and shadow for object:
	if node != null and object_data_arr.size() > 1:
		if "character" in node: #token
			print("node, polygon", node, node.token_polygon)
			node = node.token_polygon
		if object_data_arr[1][0] == "light":
			var light = PointLight2D.new()
			light.position = node.position
			var texture = GradientTexture2D.new()
			texture.gradient = Gradient.new()
			texture.gradient.set_offset(0, 0.7)
			texture.gradient.set_offset(1, 0)
			texture.height = object_data_arr[1][3]
			texture.width = texture.height
			texture.fill = GradientTexture2D.FILL_RADIAL
			texture.fill_from = Vector2(0.5, 0.5)
			texture.fill_to = Vector2(1, 0)
			texture.repeat = GradientTexture2D.REPEAT_NONE
			light.texture = texture
			light.texture_scale = object_data_arr[1][4]
			light.color = object_data_arr[1][1]
			light.energy = object_data_arr[1][2]
			light.range_z_max = 4095
			light.range_z_min = -4096
			light.range_layer_max = 0
			light.range_layer_min = -512
			light.shadow_enabled = true
			light.range_item_cull_mask = Globals.draw_layer.light_mask
			light.shadow_item_cull_mask = Globals.draw_layer.light_mask
			light.set_meta("type", "light")
			node.add_sibling(light)
			light.name = object_data_arr[1][6]
			node.set_meta("light", true)
			var remote = RemoteTransform2D.new()
			remote.update_scale = false
			remote.position = object_data_arr[1][5]
			remote.set_meta("light", true)
			remote.set_meta("type", "remote")
			node.add_child(remote)
			remote.name = object_data_arr[1][7]
			remote.set_remote_node(remote.get_path_to(light))

		elif object_data_arr[1][0] == "shadow":
			var occluder = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.polygon = object_data_arr[1][1]
			occluder.occluder.cull_mode = object_data_arr[1][2]
			occluder.occluder_light_mask = Globals.draw_layer.light_mask
			node.add_child(occluder)
			occluder.name = object_data_arr[1][3]
			node.set_meta("shadow", true)
		if object_data_arr.size() > 2:
			if object_data_arr[2][0] == "shadow":
				var occluder = LightOccluder2D.new()
				occluder.occluder = OccluderPolygon2D.new()
				occluder.occluder.polygon = object_data_arr[2][1]
				occluder.occluder.cull_mode = object_data_arr[2][2]
				occluder.occluder_light_mask = Globals.draw_layer.light_mask
				node.add_child(occluder)
				occluder.name = object_data_arr[2][3]
				node.set_meta("shadow", true)

#func load_map(map_name, load_tokens = true):
	#self.map_name = map_name
	#if not FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name):
		#return #no save to load
	#
	#var map_save = FileAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.READ)
	#if map_save == null:
		#print("file open error - aborting")
		#return
	##load map
	#saved_layers = map_save.get_var(true)
	#map_desc = map_save.get_var()
	#grid_size = map_save.get_var()
	#image = map_save.get_var()
	#if load_tokens:
		##load tokens
		#tokens.clear()
		#token_paths.clear()
		#token_indexes.clear()
		#var token_count = map_save.get_var()
		#for i in token_count:
			#load_token(map_save)
	#map_save.close()
	#
	#return 


func save_token(save_file: FileAccess, token: Control):
	save_file.store_var(token.character.singleton)
	if token.character.singleton == false: #store character in token
		token.character.store_char_data(save_file)
	else: #store character path
		save_file.store_var(token.character.get_path_to_save())
	save_file.store_var(token.token_polygon.position)
	save_file.store_var(token.token_polygon.size)
	save_file.store_var(token.token_polygon.scale)
	save_file.store_var(token.token_polygon.rotation)
	
func load_token(save_file: FileAccess):
	var token = token_comp.instantiate()
	var character = Character.new()
	character.singleton = save_file.get_var()
	if character.singleton == false: #load character from token
		character.get_char_data(save_file)
	else:
		var path_to_save = save_file.get_var()
		
	var token_polygon = token.get_child(0)
	token_polygon.position = save_file.get_var()
	token_polygon.custom_minimum_size = save_file.get_var()
	token_polygon.size = token_polygon.custom_minimum_size
	token_polygon.scale = save_file.get_var()
	token_polygon.rotation = save_file.get_var()
	tokens.append(token)
	#set character in token
	token.character = character
	token_polygon.character = character
	
	#character.connect("attr_updated", character.apply_modifiers_to_attr)
	#character.connect("item_equipped", character.equip_item)
	#character.connect("item_unequipped", character.unequip_item)
	character.load_equipped_items_from_equipment()
	character.load_attr_modifiers_from_equipment()
	
	Globals.draw_layer.add_child(token)

	return token

#func save_token(save_file: FileAccess, token: Control):
	#save_file.store_var(token.character.singleton)
	#if token.character.singleton == false: #store character in token
		#token.character.store_char_data(save_file)
	#save_file.store_var(token.get_parent().get_path())
	#save_file.store_var(token.get_index())
	#save_file.store_var(token.token_polygon.position)
	#save_file.store_var(token.token_polygon.size)
	#save_file.store_var(token.token_polygon.scale)
	#save_file.store_var(token.token_polygon.rotation)
	#
#func load_token(save_file: FileAccess):
	#var token = token_comp.instantiate()
	#var character = Character.new()
	#character.singleton = save_file.get_var()
	#if character.singleton == false: #load character from token
		#character.get_char_data(save_file)
	#else:
		#pass #link token to character TODO
	#var path: NodePath = save_file.get_var()
	#var index: int = save_file.get_var()
	#var token_polygon = token.get_child(0)
	#token_polygon.position = save_file.get_var()
	#token_polygon.custom_minimum_size = save_file.get_var()
	#token_polygon.size = token_polygon.custom_minimum_size
	#token_polygon.scale = save_file.get_var()
	#token_polygon.rotation = save_file.get_var()
	#tokens.append(token)
	#token_paths.append(path)
	#token_indexes.append(index)
	##set character in token
	#token.character = character
	#token_polygon.character = character
	#
	#character.connect("attr_updated", character.apply_modifiers_to_attr)
	#character.connect("item_equipped", character.equip_item)
	#character.connect("item_unequipped", character.unequip_item)
	#
	#character.load_equipped_items_from_equipment()
	#character.load_attr_modifiers_from_equipment()

func add_token(token):
	tokens.append(token)

func remove_token(token):
	tokens.erase(token)

func remove_tokens_from_token_array():
	var erased_token_index_arr = []
	for i in range(tokens.size()-1, -1, -1): #going in reverse order - for remove_at(i)
		if tokens[i] == null:
			erased_token_index_arr.append(i)
	for i in erased_token_index_arr:
		tokens.remove_at(i)
