extends Window

enum Tools{SELECT, LABEL, INPUT, POLYGON, IMAGE}

var tool = Tools.SELECT

var zoom = 1 :
	set(value):
		zoom = value
		apply_zoom()

@onready var scroll = $HSplitContainer/CanvasScrollContainer
@onready var canvas = $HSplitContainer/CanvasScrollContainer/Canvas
@onready var node = $HSplitContainer/CanvasScrollContainer/Canvas/Node
@onready var select_box = $HSplitContainer/CanvasScrollContainer/Canvas/Node/SelectBox
@onready var canvas_scroll: ScrollContainer = $HSplitContainer/CanvasScrollContainer

@onready var opt_canvas = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/Canvas
@onready var opt_label = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/LabelOptions
@onready var opt_input = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/TextEditOptions
@onready var opt_polygon = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/PolygonOptions
@onready var opt_image = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/ImageOptions
@onready var opt_multi = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/MultipleOptions
@onready var opt_align_space = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/MultipleItemsOptions
@onready var opt_selectbox = $HSplitContainer/VBoxContainer/ScrollContainer/Settings/SelectBoxOptions

@onready var savefilediag = $SaveFileDialog
@onready var loadfilediag = $LoadFileDialog

var saved = false

var clipboard_arr = []

var current_opt = null
var current_char_sheet_name = "char_sheet"
var char_sheet_base_path = Globals.base_dir_path + "/saves/character_sheets"
var current_sheet_folder = ""

var loading = false
var creating = false
var dragging = false
var created_object
var selected_objects = []
var begin = Vector2(0,0)
var end = Vector2(0,0)

#var canvas_size = Vector2(800,1000) # char_sheet_arr[0]
#var canvas_color = Color.WHITE # char_sheet_arr[1]
var char_sheet_arr = [Vector2(800,1000), Color.WHITE, []]
var label_dict = {
	"type": "label",
	"pos": Vector2(0,0),
	"size": Vector2(0,0),
	"text": "",
	"fsize": 11,
	"lcolor": Color.BLACK,
	"width": 2,
	"BGcolor": Color.TRANSPARENT,
	"fcolor": Color.BLACK,
	"valign": VERTICAL_ALIGNMENT_TOP,
	"halign": HORIZONTAL_ALIGNMENT_LEFT
}
var input_dict = {
	"type": "input",
	"pos": Vector2(0,0),
	"size": Vector2(0,0),
	"attr": "",
	"fsize": 11,
	"lcolor": Color.BLACK,
	"width": 2,
	"BGcolor": Color.TRANSPARENT,
	"fcolor": Color.BLACK,
	"left_margin": 5
}
var polygon_dict = {
	"type": "polygon",
	"pos": Vector2(0,0),
	"size": Vector2(0,0),
	"width": 2,
	"lcolor": Color.BLACK,
	"BGcolor": Color.TRANSPARENT,
	"points": [],
}
var image_dict = {
	"type": "image",
	"pos": Vector2(0,0),
	"size": Vector2(0,0),
	"char": false,
	"attr": "char_image",
	"image": "",
}

# Called when the node enters the scene tree for the first time.
func _ready():
	#TODO load
	load_canvas_opt()
	node.remove_child(select_box)
	node.add_child(select_box, false, Node.INTERNAL_MODE_FRONT)


func get_font_size(font: Font, size, text):
	print("get_font_size")
	var n = 1
	var m = 1
	for i in range(int(size.y), 1, -1):
		print(i, " ", font.get_height(i), " ", size.y)
		if font.get_height(i) <= size.y:
			n = i
			break
	for i in range(int(size.y), 1, -1):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, i).x <= size.x:
			m = i
			break
	return min(m,n)


func apply_zoom():
	canvas.custom_minimum_size = Vector2(char_sheet_arr[0].x * zoom, char_sheet_arr[0].y * zoom)
	node.scale = Vector2(zoom, zoom)

# =============================== saving and loading =====================================

func check_save_folder():
	if not DirAccess.dir_exists_absolute(char_sheet_base_path):
		DirAccess.make_dir_recursive_absolute(char_sheet_base_path)


func _on_save_button_pressed():
	if creating: #end polygon creation
		set_polygon_pos_and_size(created_object)
		creating = false
	check_save_folder()
	savefilediag.current_file = current_char_sheet_name
	savefilediag.root_subfolder = char_sheet_base_path
	savefilediag.popup()
	


func _on_load_button_pressed():
	if creating: #end polygon creation
		set_polygon_pos_and_size(created_object)
		creating = false
	check_save_folder()
	loadfilediag.root_subfolder = char_sheet_base_path
	loadfilediag.popup()


func _on_save_file_dialog_confirmed():
	var path = char_sheet_base_path + "/" + savefilediag.current_path
	current_char_sheet_name = savefilediag.current_file
	if DirAccess.dir_exists_absolute(path):
		$ConfirmationDialog.popup()
	else:
		_on_confirmation_dialog_confirmed(path)


func _on_confirmation_dialog_confirmed(path = null):
	if path == null:
		path = char_sheet_base_path + "/" + savefilediag.current_path
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	var file = FileAccess.open(path + "/" + current_char_sheet_name + ".char_sheet", FileAccess.WRITE)
	print("arr: ", char_sheet_arr)
	print("str: ", var_to_str(char_sheet_arr))
	#file.store_var(char_sheet_arr)
	file.store_string(var_to_str(char_sheet_arr))
	current_sheet_folder = path
	saved = true
	file.close()


func _on_load_file_dialog_dir_selected(dir):
	var path = dir
	print("path: ", path)
	current_char_sheet_name = path.get_file()
	print("dir: ", current_char_sheet_name)
	var file = FileAccess.open(path + "/" + current_char_sheet_name + ".char_sheet", FileAccess.READ)
	if file == null:
		print("file is null")
		return
	char_sheet_arr = str_to_var(file.get_as_text())
	file.close()
	print(char_sheet_arr)
	for object in node.get_children():
		object.queue_free()
	selected_objects = []
	select_box.size = Vector2(0,0)
	canvas.custom_minimum_size = char_sheet_arr[0]
	canvas.get_theme_stylebox("panel").bg_color = char_sheet_arr[1]
	for dict in char_sheet_arr[2]:
		var type = dict["type"]
		if type == "label":
			load_label_from_dict(dict)
		elif type == "input":
			load_input_from_dict(dict)
		elif type == "polygon":
			load_polygon_from_dict(dict)
		elif type == "image":
			load_image_from_dict(dict)
	current_sheet_folder = path
	saved = true
	zoom = 1
			
	
func load_label_from_dict(dict):
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = dict["pos"]
	label.set_deferred("size", dict["size"])
	label.clip_text = true
	node.add_child(label)
	label.add_theme_color_override("font_color", dict["fcolor"])
	label.text = dict["text"]
	print(label.text)
	var style = StyleBoxFlat.new()
	style.bg_color = dict["BGcolor"]
	style.border_color = dict["lcolor"]
	style.set_border_width_all(dict["width"])
	label.add_theme_stylebox_override("normal", style)
	if dict["fsize"] == -1:
		dict["fsize"] = get_font_size(label.get_theme_font("font"), dict["size"], label.text)
	label.add_theme_font_size_override("font_size", dict["fsize"])
	label.vertical_alignment = dict["valign"]
	label.horizontal_alignment = dict["halign"]
	label.set_meta("dict", dict)
	label.z_as_relative = false
	label.z_index = 1
	return label
	
func load_input_from_dict(dict):
	var input = TextEdit.new()
	input.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input.position = dict["pos"]
	input.size = dict["size"]
	input.add_theme_color_override("font_color", dict["fcolor"])
	input.text = "@" + dict["attr"]
	node.add_child(input)
	var style = StyleBoxFlat.new()
	style.bg_color = dict["BGcolor"]
	style.border_color = dict["lcolor"]
	style.set_border_width_all(dict["width"])
	if dict.has("left_margin"):
		style.content_margin_left = dict["left_margin"]
	else:
		style.content_margin_left = 5
		dict["left_margin"] = 5
	input.add_theme_stylebox_override("normal", style)
	input.add_theme_font_size_override("font_size", dict["fsize"])
	input.set_meta("dict", dict)
	input.get_h_scroll_bar().visible = false
	input.get_v_scroll_bar().visible = false
	return input
	
func load_polygon_from_dict(dict):
	var polygon = CustomPolygon.new()
	polygon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(polygon)
	polygon.position = dict["pos"]
	polygon.size = dict["size"]
	polygon.points = dict["points"]
	polygon.colorLines = dict["lcolor"]
	polygon.lineWidth = dict["width"]
	polygon.colorBG = dict["BGcolor"]
	polygon.queue_redraw()
	polygon.set_meta("dict", dict)
	polygon.z_as_relative = false
	polygon.z_index = -1
	return polygon
	
func load_image_from_dict(dict):
	var image = TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(image)
	image.position = dict["pos"]
	image.size = dict["size"]
	image.set_meta("dict", dict)
	#TODO load image
	var texture = load(current_sheet_folder + "/" + dict["image"]) 
	if texture == null:
		texture = load(Globals.base_dir_path + "/images/Placeholder-1479066.png")
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	return image
# ================================== drawing ============================================

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		canvas_scroll.scroll_horizontal -= event.relative.x
		canvas_scroll.scroll_vertical -= event.relative.y
		get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton:
		if Input.is_action_pressed("ctrl"):
		#zoom
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom += 0.1
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= 0.1
				if zoom < 0.1:
					zoom = 0.1
				get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("mouseleft"): #begin drawing
			var mouse_pos = get_canvas_mouse_pos()
			if tool == Tools.SELECT:
				print("select click")
				if mouse_pos.x > select_box.position.x and mouse_pos.x < select_box.position.x + select_box.size.x and \
				mouse_pos.y > select_box.position.y and mouse_pos.y < select_box.position.y + select_box.size.y:
					dragging = true
					print("dragging")
					return
				var focus = get_window().gui_get_focus_owner() #fix for selecting object with option range selected
				if focus != null:
					focus.release_focus()
				creating = true
				begin = mouse_pos
				end = mouse_pos
				set_pos_and_size(select_box, null)
				print("created")
				
			if tool == Tools.LABEL: #create label
				created_object = Label.new()
				created_object.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var dict = label_dict.duplicate(true)
				created_object.clip_text = true
				node.add_child(created_object)
				created_object.add_theme_color_override("font_color", dict["fcolor"])
				created_object.text = dict["text"]
				var style = StyleBoxFlat.new()
				style.bg_color = dict["BGcolor"]
				style.border_color = dict["lcolor"]
				style.set_border_width_all(dict["width"])
				created_object.add_theme_stylebox_override("normal", style)
				created_object.add_theme_font_size_override("font_size", dict["fsize"])
				created_object.vertical_alignment = dict["valign"]
				created_object.horizontal_alignment = dict["halign"]
				creating = true
				begin = mouse_pos
				end = mouse_pos
				set_pos_and_size(created_object, dict)
				print("created label")
				created_object.set_meta("dict", dict)
				char_sheet_arr[2].append(dict)
				
				
			if tool == Tools.INPUT: #create input
				created_object = TextEdit.new()
				created_object.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var dict = input_dict.duplicate(true)
				node.add_child(created_object)
				created_object.add_theme_color_override("font_color", dict["fcolor"])
				created_object.text = "@" + dict["attr"]
				var style = StyleBoxFlat.new()
				style.bg_color = dict["BGcolor"]
				style.border_color = dict["lcolor"]
				style.set_border_width_all(dict["width"])
				style.content_margin_left = dict["left_margin"]
				created_object.add_theme_stylebox_override("normal", style)
				created_object.add_theme_font_size_override("font_size", dict["fsize"])
				creating = true
				begin = mouse_pos
				end = mouse_pos
				set_pos_and_size(created_object, dict)
				print("created input")
				created_object.set_meta("dict", dict)
				created_object.get_h_scroll_bar().visible = false
				created_object.get_v_scroll_bar().visible = false
				char_sheet_arr[2].append(dict)
				
			if tool == Tools.POLYGON:
				if not creating: #create polygon
					var dict = polygon_dict.duplicate(true)
					dict["points"] = []
					created_object = CustomPolygon.new()
					created_object.mouse_filter = Control.MOUSE_FILTER_IGNORE
					node.add_child(created_object)
					creating = true
					begin = mouse_pos
					created_object.position = mouse_pos
					created_object.points.append(mouse_pos-begin)
					dict["points"] = created_object.points
					created_object.colorLines = dict["lcolor"]
					created_object.lineWidth = dict["width"]
					created_object.colorBG = dict["BGcolor"]
					created_object.queue_redraw()
					print("created polygon")
					created_object.set_meta("dict", dict)
					char_sheet_arr[2].append(dict)
				else: #add point to polygon
					if abs(mouse_pos.x - begin.x) < created_object.lineWidth and abs(mouse_pos.x - begin.x) < created_object.lineWidth:
						created_object.points.append(Vector2(0,0))
						created_object.queue_redraw()
						set_polygon_pos_and_size(created_object)
						creating = false
					else:
						created_object.points.append(mouse_pos-begin)
						created_object.queue_redraw()
				
			if tool == Tools.IMAGE: #create image
				created_object = TextureRect.new()
				created_object.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				created_object.stretch_mode = TextureRect.STRETCH_SCALE
				created_object.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var dict = image_dict.duplicate(true)
				node.add_child(created_object)
				creating = true
				begin = mouse_pos
				end = mouse_pos
				set_pos_and_size(created_object, dict)
				print("created image")
				var texture = load(current_sheet_folder + "/" + dict["image"]) 
				if texture == null:
					texture = load(Globals.base_dir_path + "/images/Placeholder-1479066.png")
				created_object.texture = texture
				created_object.set_meta("dict", dict)
				char_sheet_arr[2].append(dict)
				
		if Input.is_action_just_released("mouseleft"): #end drawing or dragging
			var mouse_pos = get_canvas_mouse_pos()
			if tool == Tools.SELECT:
				if dragging:
					var dict
					for object in selected_objects:
						dict = object.get_meta("dict")
						dict["pos"] = object.position
					reload_opt(dict)
					dragging = false
				elif creating:
					end = mouse_pos
					select_selection()
					creating = false
			if tool != Tools.POLYGON:
				if creating:
					end = mouse_pos
					set_pos_and_size(created_object, created_object.get_meta("dict"))
					creating = false
				
	if event is InputEventMouseMotion:
		if creating:
			if tool == Tools.SELECT:
				var mouse_pos = get_canvas_mouse_pos()
				end = mouse_pos
				set_pos_and_size(select_box, null)
			elif tool != Tools.POLYGON:
				var mouse_pos = get_canvas_mouse_pos()
				end = mouse_pos
				set_pos_and_size(created_object, created_object.get_meta("dict"))
		elif dragging:
			var offset = event.relative / Vector2(zoom, zoom)
			select_box.position += offset
			for object in selected_objects:
				object.position += offset
			var dict = selected_objects[-1].get_meta("dict")
			dict["pos"] = selected_objects[-1].position
			reload_opt(dict)
			load_selectbox_opt()
			
	if event is InputEventKey:
		if Input.is_action_just_pressed("Delete"):
			for object in selected_objects:
				char_sheet_arr[2].erase(object.get_meta("dict"))
				object.queue_free()
			select_box.size = Vector2(0,0)
			selected_objects.clear()
			show_selected_options()
		if Input.is_action_just_pressed("ui_copy"):
			clipboard_arr.clear()
			var local_select_box_pos = get_select_box_local_pos()
			for object in selected_objects:
				var dict: Dictionary = object.get_meta("dict").duplicate(true)
				dict["pos"] = object.position - local_select_box_pos
				print("copy position: ", dict["pos"])
				clipboard_arr.append(dict)
		if Input.is_action_just_pressed("ui_cut"):
			clipboard_arr.clear()
			var local_select_box_pos = get_select_box_local_pos()
			for object in selected_objects:
				var dict: Dictionary = object.get_meta("dict")
				char_sheet_arr[2].erase(object.get_meta("dict"))
				dict = dict.duplicate(true)
				dict["pos"] = object.position - local_select_box_pos
				clipboard_arr.append(dict)
			for object in selected_objects:
				object.queue_free()
			select_box.size = Vector2(0,0)
			selected_objects.clear()
			show_selected_options()
		if Input.is_action_just_pressed("ui_paste"):
			selected_objects.clear()
			var mouse_pos = get_canvas_mouse_pos()
			for dict in clipboard_arr:
				var new_dict = dict.duplicate(true)
				char_sheet_arr[2].append(new_dict)
				var type = new_dict["type"]
				new_dict["pos"] += mouse_pos
				print("paste position: ", new_dict["pos"], mouse_pos)
				if type == "label":
					selected_objects.append(load_label_from_dict(new_dict))
				elif type == "input":
					selected_objects.append(load_input_from_dict(new_dict))
				elif type == "polygon":
					selected_objects.append(load_polygon_from_dict(new_dict))
				elif type == "image":
					selected_objects.append(load_image_from_dict(new_dict))
			recalculate_select_box()

# ================================== tool selection ===================================================
func _on_select_toggled(toggled_on):
	if toggled_on:
		if creating:
			set_polygon_pos_and_size(created_object)
			creating = false
		tool = Tools.SELECT
		show_selected_options()


func _on_label_toggled(toggled_on):
	if toggled_on:
		if creating:
			set_polygon_pos_and_size(created_object)
			creating = false
		tool = Tools.LABEL
		show_selected_options()


func _on_input_toggled(toggled_on):
	if toggled_on:
		if creating:
			set_polygon_pos_and_size(created_object)
			creating = false
		tool = Tools.INPUT
		show_selected_options()


func _on_polygon_toggled(toggled_on):
	if toggled_on:
		if creating:
			set_polygon_pos_and_size(created_object)
			creating = false
		tool = Tools.POLYGON
		show_selected_options()


func _on_image_toggled(toggled_on):
	if toggled_on:
		if creating:
			set_polygon_pos_and_size(created_object)
			creating = false
		tool = Tools.IMAGE
		show_selected_options()

# ======================================= select functions =================================

#returns pos and size based on begin and end
func get_pos_and_size():
	if begin.x < end.x: #begin left of end
		if begin.y < end.y: #begin above end
			return [begin, end-begin]
		else: #begin below end
			return [Vector2(begin.x, end.y), Vector2(end.x-begin.x, begin.y-end.y)]
	else: #begin right of end
		if begin.y < end.y: #begin above end
			return [Vector2(end.x, begin.y), Vector2(begin.x-end.x, end.y-begin.y)]
		else: #begin below end
			return [end, begin-end]
			
#sets pos and size based on begin and end for object
func set_pos_and_size(object, dict):
	if begin.x < end.x: #begin left of end
		if begin.y < end.y: #begin above end
			object.position = begin
			object.size = end-begin
		else: #begin below end
			object.position = Vector2(begin.x, end.y)
			object.size = Vector2(end.x-begin.x, begin.y-end.y)
	else: #begin right of end
		if begin.y < end.y: #begin above end
			object.position = Vector2(end.x, begin.y)
			object.size = Vector2(begin.x-end.x, end.y-begin.y)
		else: #begin below end
			object.position = end
			object.size = begin-end
	if dict != null:
		dict["pos"] = object.position
		dict["size"] = object.size
	
	
func select_selection():
	var select_pos_local = get_select_box_local_pos()
	var found = false
	if not Input.is_action_pressed("shift"):
		selected_objects.clear()
	else:
		print("shift held ", selected_objects)
	for object in node.get_children():
		if object is Control:
			print(object.name)
			if object.position.x >= select_pos_local.x and \
			object.position.y >= select_pos_local.y and \
			object.position.x + object.size.x <= select_pos_local.x + select_box.size.x and \
			object.position.y + object.size.y <= select_pos_local.y + select_box.size.y:
				#object in area
				print("object in area")
				selected_objects.append(object)
				found = true
	if not found: #nothing selected - get clicked
		for object in node.get_children():
			if object is Control:
				var mouse_pos = get_canvas_mouse_pos()
				print(object.name)
				if object.position.x <= mouse_pos.x and \
				object.position.y <= mouse_pos.y and \
				object.position.x + object.size.x >= mouse_pos.x and \
				object.position.y + object.size.y >= mouse_pos.y:
					selected_objects.append(object)
					break
	#snap selection to objects
	recalculate_select_box()
	print(selected_objects)
	load_selectbox_opt()
	show_selected_options()

func recalculate_select_box():
	if selected_objects.is_empty():
		return
	var max_x = selected_objects[0].position.x
	var max_y = selected_objects[0].position.y
	var min_x = selected_objects[0].position.x
	var min_y = selected_objects[0].position.y
	for object in selected_objects:
		if object.position.x + object.size.x > max_x:
			max_x = object.position.x + object.size.x
		if object.position.x < min_x:
			min_x = object.position.x
		if object.position.y + object.size.y > max_y:
			max_y = object.position.y + object.size.y
		if object.position.y < min_y:
			min_y = object.position.y
	select_box.position = Vector2(min_x, min_y) - node.position
	select_box.size = Vector2(max_x-min_x, max_y-min_y)

func get_canvas_mouse_pos():
	return node.get_local_mouse_position()
		
func set_polygon_pos_and_size(object):
	if object.points.is_empty():
		print("no points in polygon - free")
		object.queue_free()
		return
	var max_x = 0
	var max_y = 0
	var min_x = 0
	var min_y = 0
	for point in object.points:
		if point.x > max_x:
			max_x = point.x
		if point.x < min_x:
			min_x = point.x
		if point.y > max_y:
			max_y = point.y
		if point.y < min_y:
			min_y = point.y
	var diff = Vector2(min_x, min_y)
	print("diff = ", diff)
	print("points: ", object.points)
	for i in object.points.size():
		object.points[i] -= diff
	print("points: ", object.points)
	var dict = object.get_meta("dict")
	object.position = object.position + diff
	dict["pos"] = object.position
	object.size = Vector2(max_x - min_x, max_y - min_y)
	dict["size"] = object.size
	object.queue_redraw()
		
func show_selected_options():
	if current_opt != null:
		current_opt.visible = false
		opt_align_space.visible = false
	if selected_objects.is_empty(): #show option for selected tool
		if tool == Tools.LABEL:
			current_opt = opt_label
		elif tool == Tools.INPUT:
			current_opt = opt_input
		elif tool == Tools.POLYGON:
			current_opt = opt_polygon
		elif tool == Tools.IMAGE:
			current_opt = opt_image
		else: #select - show nothing
			current_opt = null
			opt_selectbox.visible = false
		if current_opt != null:
			current_opt.visible = true
	else: #get selected
		opt_selectbox.visible = true
		if tool == Tools.SELECT:
			#detect type of selected objects
			var old_type = null
			var multi = false
			var dict
			for object in selected_objects:
				dict = object.get_meta("dict")
				var type = dict["type"]
				if old_type != null and old_type != type:
					multi = true
					break
				old_type = type
			if multi:
				current_opt = opt_multi
				load_multi_opt(dict)
			elif old_type == "label":
				current_opt = opt_label
				load_label_opt(dict)
			elif old_type == "input":
				current_opt = opt_input
				load_input_opt(dict)
			elif old_type == "polygon":
				current_opt = opt_polygon
				load_polygon_opt(dict)
			elif old_type == "image":
				current_opt = opt_image
				load_image_opt(dict, true)
			current_opt.visible = true
			print("opt: ", current_opt)
		if selected_objects.size() > 1:
			opt_align_space.visible = true

func reload_opt(dict):
	if current_opt == opt_multi:
		load_multi_opt(dict)
	elif current_opt == opt_label:
		load_label_opt(dict)
	elif current_opt == opt_input:
		load_input_opt(dict)
	elif current_opt == opt_polygon:
		load_polygon_opt(dict)
	elif current_opt == opt_image:
		load_image_opt(dict, false)

func load_selectbox_opt():
	loading = true
	var local_select_box_pos = get_select_box_local_pos()
	opt_selectbox.get_node("Container/PosX/SpinBox").value = local_select_box_pos.x
	opt_selectbox.get_node("Container/PosY/SpinBox").value = local_select_box_pos.y
	opt_selectbox.get_node("Container/SizeX/SpinBox").value = select_box.size.x
	opt_selectbox.get_node("Container/SizeY/SpinBox").value = select_box.size.y
	loading = false

func load_canvas_opt():
	loading = true
	opt_canvas.get_node("Container/SizeX/SpinBox").value = canvas.custom_minimum_size.x
	opt_canvas.get_node("Container/SizeY/SpinBox").value = canvas.custom_minimum_size.y
	opt_canvas.get_node("Container/Color/ColorPickerBtn").color = canvas.get_theme_stylebox("panel").bg_color
	loading = false
		
func load_multi_opt(dict):
	loading = true
	opt_multi.get_node("Container/PosX/SpinBox").value = dict["pos"].x
	opt_multi.get_node("Container/PosY/SpinBox").value = dict["pos"].y
	opt_multi.get_node("Container/SizeX/SpinBox").value = dict["size"].x
	opt_multi.get_node("Container/SizeY/SpinBox").value = dict["size"].y
	loading = false

func load_label_opt(dict):
	loading = true
	opt_label.get_node("Container/PosX/SpinBox").value = dict["pos"].x
	opt_label.get_node("Container/PosY/SpinBox").value = dict["pos"].y
	opt_label.get_node("Container/SizeX/SpinBox").value = dict["size"].x
	opt_label.get_node("Container/SizeY/SpinBox").value = dict["size"].y
	opt_label.get_node("Container/Color/ColorPickerBtn").color = dict["lcolor"]
	opt_label.get_node("Container/BorderWidth/SpinBox").value = dict["width"]
	opt_label.get_node("Container/Color2/ColorPickerBtn").color = dict["BGcolor"]
	opt_label.get_node("Container/Text/TextEdit").text = dict["text"]
	opt_label.get_node("Container/Size/SpinBox").value = dict["fsize"]
	opt_label.get_node("Container/Color3/ColorPickerBtn").color = dict["fcolor"]
	if selected_objects.size() == 1:
		opt_label.get_node("Container/Text/TextEdit").grab_focus()
	loading = false
	
func load_input_opt(dict):
	loading = true
	opt_input.get_node("Container/PosX/SpinBox").value = dict["pos"].x
	opt_input.get_node("Container/PosY/SpinBox").value = dict["pos"].y
	opt_input.get_node("Container/SizeX/SpinBox").value = dict["size"].x
	opt_input.get_node("Container/SizeY/SpinBox").value = dict["size"].y
	opt_input.get_node("Container/Color/ColorPickerBtn").color = dict["lcolor"]
	opt_input.get_node("Container/BorderWidth/SpinBox").value = dict["width"]
	opt_input.get_node("Container/Color2/ColorPickerBtn").color = dict["BGcolor"]
	opt_input.get_node("Container/Attribute/LineEdit").text = dict["attr"]
	opt_input.get_node("Container/Size/SpinBox").value = dict["fsize"]
	opt_input.get_node("Container/Color3/ColorPickerBtn").color = dict["fcolor"]
	if selected_objects.size() == 1:
		opt_input.get_node("Container/Attribute/LineEdit").grab_focus()
	loading = false
	
func load_polygon_opt(dict):
	loading = true
	opt_polygon.get_node("Container/PosX/SpinBox").value = dict["pos"].x
	opt_polygon.get_node("Container/PosY/SpinBox").value = dict["pos"].y
	
	opt_polygon.get_node("Container/lineWidth/SpinBox").value = dict["width"]
	opt_polygon.get_node("Container/LineColor/ColorPickerBtn").color = dict["lcolor"]
	opt_polygon.get_node("Container/BGColor/ColorPickerBtn").color = dict["BGcolor"]
	#get string with points
	var points_str = ""
	for point in dict["points"]:
		points_str += str(point.x) + "," + str(point.y) + "\n"
	opt_polygon.get_node("Container/Points/TextEdit").text = points_str
	loading = false
	
func load_image_opt(dict, reload_image = false):
	loading = true
	opt_image.get_node("Container/PosX/SpinBox").value = dict["pos"].x
	opt_image.get_node("Container/PosY/SpinBox").value = dict["pos"].y
	opt_image.get_node("Container/SizeX/SpinBox").value = dict["size"].x
	opt_image.get_node("Container/SizeY/SpinBox").value = dict["size"].y
	
	if reload_image:
		print("reloading image")
		if dict["image"] != "":
			opt_image.get_node("Container/Image/TextureButton").texture_normal = load(current_sheet_folder + "/" + dict["image"])
		else:
			opt_image.get_node("Container/Image/TextureButton").texture_normal = load(Globals.base_dir_path + "/images/Placeholder-1479066.png")
	opt_image.get_node("Container/CharCheckBox").button_pressed = dict["char"]
	opt_image.get_node("Container/CharSheetCheckBox").button_pressed = not dict["char"]
	if dict["char"]:
		opt_image.get_node("Container/Attribute").visible = true
	else:
		opt_image.get_node("Container/Attribute").visible = false
	loading = false

# ================================ changing options =======================================

func _on_canvas_size_x_spin_box_value_changed(value):
	canvas.custom_minimum_size.x = value
	char_sheet_arr[0].x = value


func _on_canvas_size_y_spin_box_value_changed(value):
	canvas.custom_minimum_size.y = value
	char_sheet_arr[0].y = value

func _on_pos_x_spin_box_value_changed(value):
	if loading:
		return
	for object in selected_objects:
		object.position.x = value
		object.get_meta("dict")["pos"].x = value
	recalculate_select_box()

func _on_pos_y_spin_box_value_changed(value):
	if loading:
		return
	for object in selected_objects:
		object.position.y = value
		object.get_meta("dict")["pos"].y = value
	recalculate_select_box()

func _on_size_x_spin_box_value_changed(value):
	if loading:
		return
	for object in selected_objects:
		object.size.x = value
		object.get_meta("dict")["size"].x = value
	recalculate_select_box()

func _on_size_y_spin_box_value_changed(value):
	if loading:
		return
	for object in selected_objects:
		object.size.y = value
		object.get_meta("dict")["size"].y = value
	recalculate_select_box()


func _on_canvas_color_picker_btn_color_changed(color):
	if loading:
		return
	canvas.get_theme_stylebox("panel").bg_color = color
	char_sheet_arr[1] = color


func _on_label_text_edit_text_changed():
	if loading:
		return
	var text = opt_label.get_node("Container/Text/TextEdit").text
	for object in selected_objects:
		object.text = text
		object.get_meta("dict")["text"] = text


func _on_label_font_size_spin_box_value_changed(value):
	if loading:
		return
	label_dict["fsize"] = value
	for object in selected_objects:
		object.add_theme_font_size_override("font_size", value)
		object.get_meta("dict")["fsize"] = value


func _on_input_font_size_spin_box_value_changed(value):
	if loading:
		return
	input_dict["fsize"] = value
	for object in selected_objects:
		object.add_theme_font_size_override("font_size", value)
		object.get_meta("dict")["fsize"] = value


func _on_input_attr_line_edit_text_changed(new_text):
	if loading:
		return
	for object in selected_objects:
		object.text = "@" + new_text
		object.get_meta("dict")["attr"] = new_text


func _on_poly_line_width_spin_box_value_changed(value):
	if loading:
		return
	polygon_dict["width"] = value
	for object in selected_objects:
		object.lineWidth = value
		object.get_meta("dict")["width"] = value


func _on_poly_line_color_picker_btn_color_changed(color):
	if loading:
		return
	polygon_dict["lcolor"] = color
	for object in selected_objects:
		object.colorLines = color
		object.get_meta("dict")["lcolor"] = color


func _on_poly_fill_color_picker_btn_color_changed(color):
	if loading:
		return
	polygon_dict["BGcolor"] = color
	for object in selected_objects:
		object.colorBG = color
		object.get_meta("dict")["BGcolor"] = color


func _on_text_edit_text_changed():
	var point_arr = []
	var text = opt_polygon.get_node("Container/Points/TextEdit").text
	var point_strs = text.split("\n", false)
	for point_str in point_strs:
		var xy = point_str.split_floats(",", false)
		if xy.size() > 1:
			point_arr.append(Vector2(xy[0], xy[1]))
	print("point arr: ", point_arr)
	for object in selected_objects:
		object.points = point_arr
		object.get_meta("dict")["points"] = point_arr
		set_polygon_pos_and_size(object)




func get_select_box_local_pos():
	return select_box.position + node.position


func horizontal_position_sort(a, b):
	if a.position.x < b.position.x:
		return true
	return false
	
func vertical_position_sort(a, b):
	if a.position.y < b.position.y:
		return true
	return false

func _on_horizontal_spacing_pressed():
	selected_objects.sort_custom(horizontal_position_sort)
	var spacing = 0
	for object in selected_objects:
		spacing += object.size.x
	spacing = (select_box.size.x - spacing) / (selected_objects.size()-1)
	space_out_horizontal(spacing)
	
func space_out_horizontal(spacing):
	var current = get_select_box_local_pos().x
	for object in selected_objects:
		object.position.x = current
		object.get_meta("dict")["pos"].x = object.position.x
		current += object.size.x + spacing

func _on_vertical_spacing_pressed():
	selected_objects.sort_custom(vertical_position_sort)
	var spacing = 0
	for object in selected_objects:
		spacing += object.size.y
	spacing = (select_box.size.y - spacing) / (selected_objects.size()-1)
	space_out_vertical(spacing)
	
func space_out_vertical(spacing):
	var current = get_select_box_local_pos().y
	for object in selected_objects:
		object.position.y = current
		object.get_meta("dict")["pos"].y = object.position.y
		current += object.size.y + spacing


func _on_horizontal_spacing_size_pressed():
	selected_objects.sort_custom(horizontal_position_sort)
	space_out_horizontal($HSplitContainer/VBoxContainer/ScrollContainer/Settings/MultipleItemsOptions/Container/SpacingSpinBox.value)
	recalculate_select_box()


func _on_vertical_spacing_size_pressed():
	selected_objects.sort_custom(vertical_position_sort)
	space_out_vertical($HSplitContainer/VBoxContainer/ScrollContainer/Settings/MultipleItemsOptions/Container/SpacingSpinBox.value)
	recalculate_select_box()



func _on_vertical_align_top_pressed():
	var y = get_select_box_local_pos().y
	for object in selected_objects:
		object.position.y = y
		object.get_meta("dict")["pos"].y = object.position.y
	recalculate_select_box()


func _on_vertical_align_center_pressed():
	var y = get_select_box_local_pos().y + (select_box.size.y / 2)
	for object in selected_objects:
		object.position.y = y - (object.size.y / 2)
		object.get_meta("dict")["pos"].y = object.position.y
	recalculate_select_box()


func _on_vertical_align_bottom_pressed():
	var y = get_select_box_local_pos().y + select_box.size.y
	for object in selected_objects:
		object.position.y = y - object.size.y
		object.get_meta("dict")["pos"].y = object.position.y
	recalculate_select_box()


func _on_horizontal_align_left_pressed():
	var x = get_select_box_local_pos().x
	for object in selected_objects:
		object.position.x = x
		object.get_meta("dict")["pos"].x = object.position.x
	recalculate_select_box()


func _on_horizontal_align_center_pressed():
	var x = get_select_box_local_pos().x + (select_box.size.x / 2)
	for object in selected_objects:
		object.position.x = x - object.size.x / 2
		object.get_meta("dict")["pos"].x = object.position.x
	recalculate_select_box()


func _on_horizontal_align_right_pressed():
	var x = get_select_box_local_pos().x + select_box.size.x
	for object in selected_objects:
		object.position.x = x - object.size.x
		object.get_meta("dict")["pos"].x = object.position.x
	recalculate_select_box()


func _on_select_pos_x_spin_box_value_changed(value):
	if loading:
		return
	var diff = value - get_select_box_local_pos().x
	select_box.position.x = value - node.position.x
	var dict
	for object in selected_objects:
		object.position.x += diff
		dict = object.get_meta("dict")
		dict["pos"] = object.position
	reload_opt(dict) #TODO CHECK IF NEEDED


func _on_select_pos_y_spin_box_value_changed(value):
	if loading:
		return
	var diff = value - get_select_box_local_pos().y
	select_box.position.y = value - node.position.y
	var dict
	for object in selected_objects:
		object.position.y += diff
		dict = object.get_meta("dict")
		dict["pos"] = object.position
	reload_opt(dict) #TODO CHECK IF NEEDED


func _on_close_requested():
	self.hide()
	self.queue_free()


func _on_label_border_color_picker_btn_color_changed(color):
	if loading:
		return
	label_dict["lcolor"] = color
	for object in selected_objects:
		var style = object.get_theme_stylebox("normal")
		style.border_color = color
		object.get_meta("dict")["lcolor"] = color


func _on_label_border_width_spin_box_value_changed(value):
	if loading:
		return
	label_dict["width"] = value
	for object in selected_objects:
		var style = object.get_theme_stylebox("normal")
		style.set_border_width_all(value)
		object.get_meta("dict")["width"] = value


func _on_label_fill_color_picker_btn_color_changed(color):
	if loading:
		return
	label_dict["BGcolor"] = color
	for object in selected_objects:
		var style = object.get_theme_stylebox("normal")
		style.bg_color = color
		object.get_meta("dict")["BGcolor"] = color


func _on_label_font_color_picker_btn_color_changed(color):
	if loading:
		return
	label_dict["fcolor"] = color
	for object in selected_objects:
		object.add_theme_color_override("font_color", color)
		object.get_meta("dict")["fcolor"] = color


func _on_input_border_color_picker_btn_color_changed(color):
	if loading:
		return
	input_dict["lcolor"] = color
	for object in selected_objects:
		var style = object.get_theme_stylebox("normal")
		style.border_color = color
		object.get_meta("dict")["lcolor"] = color


func _on_input_border_width_spin_box_value_changed(value):
	if loading:
		return
	input_dict["width"] = value
	for object in selected_objects:
		var style = object.get_theme_stylebox("normal")
		style.set_border_width_all(value)
		object.get_meta("dict")["width"] = value


func _on_input_fill_color_picker_btn_color_changed(color):
	if loading:
		return
	input_dict["BGcolor"] = color
	for object in selected_objects:
		var style = object.get_theme_stylebox("normal")
		style.bg_color = color
		object.get_meta("dict")["BGcolor"] = color


func _on_input_font_color_picker_btn_color_changed(color):
	if loading:
		return
	input_dict["fcolor"] = color
	for object in selected_objects:
		object.add_theme_color_override("font_color", color)
		object.get_meta("dict")["fcolor"] = color


func _on_select_type_label_pressed():
	var new_selected_objects = []
	for object in selected_objects:
		if object is Label:
			new_selected_objects.append(object)
	selected_objects = new_selected_objects
	recalculate_select_box()
	show_selected_options()


func _on_select_type_input_pressed():
	var new_selected_objects = []
	for object in selected_objects:
		if object is TextEdit:
			new_selected_objects.append(object)
	selected_objects = new_selected_objects
	recalculate_select_box()
	show_selected_options()


func _on_select_type_polygon_pressed():
	var new_selected_objects = []
	for object in selected_objects:
		if object is CustomPolygon:
			new_selected_objects.append(object)
	selected_objects = new_selected_objects
	recalculate_select_box()
	show_selected_options()


func _on_select_type_image_pressed():
	var new_selected_objects = []
	for object in selected_objects:
		if object is TextureRect:
			new_selected_objects.append(object)
	selected_objects = new_selected_objects
	recalculate_select_box()
	show_selected_options()


func _on_char_check_box_toggled(toggled_on):
	if loading:
		return
	if toggled_on:
		image_dict["char"] = true
		for object in selected_objects:
			object.get_meta("dict")["char"] = true
		$HSplitContainer/VBoxContainer/ScrollContainer/Settings/ImageOptions/Container/Attribute.visible = true
	


func _on_char_sheet_check_box_toggled(toggled_on):
	if loading:
		return
	if toggled_on:
		image_dict["char"] = false
		for object in selected_objects:
			object.get_meta("dict")["char"] = false
		$HSplitContainer/VBoxContainer/ScrollContainer/Settings/ImageOptions/Container/Attribute.visible = false


func _on_image_texture_button_pressed():
	if saved:
		$ImageFileDialog.popup()
	else:
		$AcceptDialog.popup()


func _on_accept_dialog_confirmed():
	check_save_folder()
	savefilediag.current_file = current_char_sheet_name
	savefilediag.root_subfolder = char_sheet_base_path
	$SaveFileDialog.popup()


func _on_image_file_dialog_file_selected(path):
	var texture: Texture2D = load(path)
	if texture == null:
		return
	var file_name = path.get_file()
	var new_path = current_sheet_folder + "/" + file_name
	DirAccess.copy_absolute(path, new_path)
	image_dict["image"] = file_name
	opt_image.get_node("Container/Image/TextureButton").texture_normal = texture
	for object in selected_objects:
		object.texture = texture
		object.get_meta("dict")["image"] = file_name


func _on_image_attr_line_edit_text_changed(new_text):
	if loading:
		return
	image_dict["attr"] = new_text
	for object in selected_objects:
		object.get_meta("dict")["attr"] = new_text


func _on_label_horz_align_option_button_item_selected(index):
	if loading:
		return
	if index == 0:
		label_dict["halign"] = HORIZONTAL_ALIGNMENT_LEFT
		for object: Label in selected_objects:
			object.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			object.get_meta("dict")["halign"] = HORIZONTAL_ALIGNMENT_LEFT
	elif index == 1:
		label_dict["halign"] = HORIZONTAL_ALIGNMENT_CENTER
		for object: Label in selected_objects:
			object.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			object.get_meta("dict")["halign"] = HORIZONTAL_ALIGNMENT_CENTER
	else:
		label_dict["halign"] = HORIZONTAL_ALIGNMENT_RIGHT
		for object: Label in selected_objects:
			object.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			object.get_meta("dict")["halign"] = HORIZONTAL_ALIGNMENT_RIGHT


func _on_label_vert_align_option_button_item_selected(index):
	if loading:
		return
	if index == 0:
		label_dict["valign"] = VERTICAL_ALIGNMENT_TOP
		for object: Label in selected_objects:
			object.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			object.get_meta("dict")["valign"] = VERTICAL_ALIGNMENT_TOP
	elif index == 1:
		label_dict["valign"] = VERTICAL_ALIGNMENT_CENTER
		for object: Label in selected_objects:
			object.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			object.get_meta("dict")["valign"] = VERTICAL_ALIGNMENT_CENTER
	else:
		label_dict["valign"] = VERTICAL_ALIGNMENT_BOTTOM
		for object: Label in selected_objects:
			object.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			object.get_meta("dict")["valign"] = VERTICAL_ALIGNMENT_BOTTOM
