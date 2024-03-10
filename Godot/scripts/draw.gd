#Author: Vladimír Horák
#Desc:
#Script implementing all of map drawing and selecting functionality

extends Node2D

var char_sheet = preload("res://UI/character_sheet.tscn")
var inventory_sheet = preload("res://components/container_inventory.tscn")

#drawing
var pressed = false
var draw_enable = true
var current_panel: Panel #rect
var current_line: Line2D
var current_rect: ColorRect
var current_label: Label
var current_textedit: TextEdit
var currently_editing_label: Label
var currently_editing_textedit: TextEdit
var current_circle: CustomCircle
var current_ellipse: CustomEllipse
var current_arc: CustomArc
var current_measure = []
var begin: Vector2
var min_max_x_y: Vector4 # min_x min_y max_x max_y

#select
var select_box: Panel #visual setection box
var selected = [] #list of selected items
var selected_tokens = [] #list of selected tokens - for changing fov opacity and visibility of UI
var mouse_over_selected = false
var selected_creating = false
var selected_dragging = false
var selected_scaling = false
var selected_rotating = false
#hadles around selection - top bottom left right
var mouse_over_tl = false
var mouse_over_bl = false
var mouse_over_tr = false
var mouse_over_br = false
var mouse_over_rotate = false

var select_center_pos: Vector2
var select_size_org: Vector2
var select_pos_org: Vector2
var select_rot_org: float
var selected_org_scales = []
var selected_org_pos = []
var selected_org_rots = []
var flip_x = false
var flip_y = false
var oposite_corner_pos_in_world = null

var targeting = false #targeting bool
var targeting_shape = null
var targeting_origin = null #vector2 or null
var targeting_point_radius = -1
var targeting_range_circle = null #circle showing range
var targeting_self = false

var mouse_pos = Vector2(0,0)

var last_event_pos = Vector2(-1,-1)

var unshaded_material: CanvasItemMaterial

@export var layers_root: Node2D = null

@onready var layer_tree = $"../CanvasLayer/Layers/Tree"
@onready var tool_panel_object_menu = $"../CanvasLayer/HSplitContainer/VSplitContainer/ToolPanel/TabContainer/Object"
@onready var tool_panel_map_menu = $"../CanvasLayer/HSplitContainer/VSplitContainer/ToolPanel/TabContainer/Map"

signal targeting_end(selected_targets)

func _ready():
	Globals.draw_comp = self
	
	get_viewport().files_dropped.connect(on_files_dropped) #drag and drop images
	#editing selected transforms
	tool_panel_object_menu.connect("object_change", _on_object_change_signal)
	#edited fov opacity in map options -> update all fov objects
	tool_panel_map_menu.connect("fov_opacity_changed", _on_fov_opacity_changed_signal)
	
	unshaded_material = load("res://materials/canvas_item_material_unshaded.tres")
	
	#selected token in turn order:
	Globals.turn_order.connect("token_turn_selected", select_token)
	

func _unhandled_input(event):
#	print_tree_pretty() #DEBUG TODO remove
	if event is InputEventMouse:
		if Globals.draw_layer == null: #check if layer is selected
			return
		mouse_pos = get_global_mouse_position()
		if Globals.snapping == true:
	#		var snapping_camera_adjusted = get_node("../Camera2D").zoom
	#		var snapping_camera_offset = Vector2(fmod(get_node("../Camera2D").position.x, 70), fmod(get_node("../Camera2D").position.y, 70))
	#		if snapping_camera_offset.x < 0:
	#			snapping_camera_offset.x = 70 + snapping_camera_offset.x
	#		if snapping_camera_offset.y < 0:
	#			snapping_camera_offset.y = 70 + snapping_camera_offset.y
	##		print(snapping_camera_adjusted)
	#		print(get_node("../Camera2D").position)
	#		print (event.position)
	#		print (snapping_camera_offset)
	#		var posxmod = fmod((event.position.x + snapping_camera_offset.x), 70 * snapping_camera_adjusted.x)
	#		if posxmod < 70/2:
	#			event.position.x -= posxmod
	#		else:
	#			event.position.x += (70-posxmod)
	#		var posymod = fmod((event.position.y + snapping_camera_offset.y), 70 * snapping_camera_adjusted.y)
	#		if posymod < 70/2:
	#			event.position.y -= posymod
	#		else:
	#			event.position.y += (70-posymod)
				
	#		print(Vector2(fmod(get_node("../Camera2D").position.x, 70), fmod(get_node("../Camera2D").position.y, 70)))
	#		event.position = 70 * round(event.position/70)
	#		print(event.position)

#			print(mouse_pos)
			mouse_pos = round(mouse_pos/(70/Globals.snappingFraction))*(70/Globals.snappingFraction) #snap to grid
#			print(mouse_pos)
		#skip if position not changed
	#	if last_event_pos == event.position:
	#		return
	#	else:
	#		last_event_pos = event.position
		if targeting and Input.is_action_just_pressed("mouseleft"): #targeting end
			end_targeting()
			return
		if targeting and event is InputEventMouseMotion: #targeting moved mouse
			update_targeting()
			return
		#double click - open character sheet if selected
		if Globals.tool == "select" and event is InputEventMouseButton and event.double_click:
			if selected.size() == 1:
				if "character" in selected[0]: #single token - open character sheet
					var ch_sh = char_sheet.instantiate()
					ch_sh.character = selected[0].character
					Globals.windows.add_child(ch_sh)

		#button pressed or mouse moved
		if Input.is_action_just_pressed("mouseleft") and Globals.mouseOverButton:
			draw_enable = false
			return
		#pressed (not button)
		if Input.is_action_just_pressed("mouseleft"):
			print("mouse pressed")
			Globals.tool_bar.grab_focus()
			draw_enable = true
		#end any dragging
		if Input.is_action_just_released("mouseleft"):
			print("mouse released")
			pressed = false
		#line drawing finished
		if Input.is_action_just_released("mouseleft") and Globals.tool == "lines":
			if current_rect == null:
				return
			if min_max_x_y.x == min_max_x_y.z and min_max_x_y.y == min_max_x_y.w:
				#lines.remove_child(current_rect)
				current_rect.queue_free()
				print("free")
				return
			#setting size of box around line for selection purposes
			current_rect.set_begin(Vector2(min_max_x_y.x, min_max_x_y.y))
			current_rect.set_end(Vector2(min_max_x_y.z, min_max_x_y.w))
			current_line.position = -current_rect.position
			current_rect = null

		if Input.is_action_just_released("mouseleft") and Globals.tool == "measure":
			for child in current_measure:
				child.queue_free()
			current_measure.clear()

		#select box drawing | scaling finished
		if Input.is_action_just_released("mouseleft") and Globals.tool == "select":
			print("mouse released with select - scaling: " + str(selected_scaling))
			#drag finished
			if selected_dragging:
				selected_dragging = false
				return
			#rotating selection finished
			if selected_rotating:
				selected_rotating = false
				return
			#scaling selection finished
			if selected_scaling:
				print("scaling end")
				selected_scaling = false
				flip_x = false
				flip_y = false
				if mouse_over_tl:
					current_panel = select_box.get_child(0)
					if mouse_pos.x > current_panel.position.x and mouse_pos.x < current_panel.position.x + current_panel.size.x:
						if mouse_pos.y > current_panel.position.y and mouse_pos.y < current_panel.position.y + current_panel.size.y:
							return
#					mouse_over_tl = false
				if mouse_over_bl:
					current_panel = select_box.get_child(1)
					if mouse_pos.x > current_panel.position.x and mouse_pos.x < current_panel.position.x + current_panel.size.x:
						if mouse_pos.y > current_panel.position.y and mouse_pos.y < current_panel.position.y + current_panel.size.y:
							return
#					mouse_over_bl = false
				if mouse_over_tr:
					current_panel = select_box.get_child(2)
					if mouse_pos.x > current_panel.position.x and mouse_pos.x < current_panel.position.x + current_panel.size.x:
						if mouse_pos.y > current_panel.position.y and mouse_pos.y < current_panel.position.y + current_panel.size.y:
							return
#					mouse_over_tr = false
				if mouse_over_br:
					current_panel = select_box.get_child(3)
					if mouse_pos.x > current_panel.position.x and mouse_pos.x < current_panel.position.x + current_panel.size.x:
						if mouse_pos.y > current_panel.position.y and mouse_pos.y < current_panel.position.y + current_panel.size.y:
							return
#					mouse_over_br = false
				return
			if !selected_creating:
				return
			#selection box finished drawing
			selected_creating = false
			selected.clear()
			if select_box == null:
				return
			var lines_children = Globals.draw_layer.get_children()
			#max select box size and position based on drawn size
			var max_x = select_box.position.x
			var max_y = select_box.position.y
			var min_x = select_box.size.x + select_box.position.x
			var min_y = select_box.size.y + select_box.position.y
			#snap selection size to children
			for child in lines_children:
				if "character" in child: #if character token
					child = child.get_child(0)
				if child.is_class("Node2D"): #inherits from Node2D
					if Globals.select_recursive:
						if child.get_class() == "Node2D": #is Node2D -> Layer
							lines_children.append_array(child.get_children())
					continue
				if child.rotation == 0: #no rotation - faster
					if child.position.x >= select_box.position.x and child.position.y >= select_box.position.y:
						if child.position.x + child.size.x*child.scale.x <= select_box.position.x + select_box.size.x:
							if child.position.y + child.size.y*child.scale.y <= select_box.position.y + select_box.size.y:
								selected.append(child)
								if child.scale.x > 0:
									if child.position.x < min_x:
										min_x = child.position.x
									if child.position.x + child.size.x*child.scale.x > max_x:
										max_x = child.position.x + child.size.x*child.scale.x
								else:
									if child.position.x + child.size.x*child.scale.x < min_x:
										min_x = child.position.x + child.size.x*child.scale.x
									if child.position.x > max_x:
										max_x = child.position.x
								if child.scale.y > 0:
									if child.position.y < min_y:
										min_y = child.position.y
									if child.position.y + child.size.y*child.scale.y > max_y:
										max_y = child.position.y + child.size.y*child.scale.y
								else:
									if child.position.y + child.size.y*child.scale.y < min_y:
										min_y = child.position.y + child.size.y*child.scale.y
								if child.position.y > max_y:
										max_y = child.position.y
				else: #rotated object - locate corners then decide
					var diagonal = Vector2(0,0).distance_to(child.size * child.scale)
					var angle = Vector2(0,0).angle_to_point(child.size * child.scale)
					var top_left = child.position
					var top_right = Vector2(child.position.x + child.size.x * child.scale.x * cos(child.rotation), child.position.y + child.size.x * child.scale.x * sin(child.rotation))
					var bottom_right = Vector2(child.position.x + diagonal * cos(angle + child.rotation), child.position.y + diagonal * sin(angle + child.rotation))
					var bottom_left = Vector2(child.position.x + child.size.y * child.scale.y * cos(deg_to_rad(90) + child.rotation), child.position.y + child.size.y * child.scale.y * sin(deg_to_rad(90) + child.rotation))
					print("located corners: ", top_left, top_right, bottom_left, bottom_right)
					print ("bounds: ", select_box.get_begin(), select_box.get_end())
					var max = Vector2()#max x,y of rotated polygon
					var min = Vector2()#min x,y of rotated polygon
					max.x = top_left.x
					max.y = top_left.y
					if top_right.x > max.x:
						max.x = top_right.x
					if top_right.y > max.y:
						max.y = top_right.y
					if bottom_right.x > max.x:
						max.x = bottom_right.x
					if bottom_right.y > max.y:
						max.y = bottom_right.y
					if bottom_left.x > max.x:
						max.x = bottom_left.x
					if bottom_left.y > max.y:
						max.y = bottom_left.y
					#get min
					min.x = top_left.x
					min.y = top_left.y
					if top_right.x < min.x:
						min.x = top_right.x
					if top_right.y < min.y:
						min.y = top_right.y
					if bottom_right.x < min.x:
						min.x = bottom_right.x
					if bottom_right.y < min.y:
						min.y = bottom_right.y
					if bottom_left.x < min.x:
						min.x = bottom_left.x
					if bottom_left.y < min.y:
						min.y = bottom_left.y
					var b = select_box.get_begin()
					var e = select_box.get_end()
					print(b, min, e, max)
					if min.x >= b.x and min.y >= b.y:
						if max.x <= e.x:
							if max.y <= e.y:
								selected.append(child)
								if max.x > max_x:
									max_x = max.x
								if max.y > max_y:
									max_y = max.y
								if min.x < min_x:
									min_x = min.x
								if min.y < min_y:
									min_y = min.y
				min_max_x_y = Vector4(min_x, min_y, max_x, max_y)
			#if nothing in dragged square -> get clicked
			if selected.is_empty():
				var clicked = get_clicked(mouse_pos)
				if clicked != null:
					selected.append(clicked)
				
			select_objects()
		#circle or rect drawing finished
		if Input.is_action_just_released("mouseleft") and (Globals.tool == "rect" or Globals.tool == "circle"):
			if current_panel == null:
				return
			print_tree_pretty()
			#current_panel.rotation_degrees = 30
			print("rect finished")
			print(current_panel.size)
			print(current_panel.position)
			print(get_global_mouse_position())
			if current_panel.size.x == 0 or current_panel.size.y == 0:
				#lines.remove_child(current_panel)
				current_panel.queue_free()
				print("free")
		#else button held -> drawing
		if draw_enable:
			if Globals.tool == "rect":
				if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					pressed = event.pressed
					#just pressed - create objects
					if pressed:
						current_panel = Panel.new()
						current_panel.mouse_filter = Control.MOUSE_FILTER_PASS
						begin = mouse_pos
						current_panel.set_begin(begin)
						current_panel.set_end(begin)
						var style = StyleBoxFlat.new()
						style.bg_color = Globals.colorBack
						style.border_color = Globals.colorLines
						style.set_border_width_all(Globals.lineWidth)
						current_panel.add_theme_stylebox_override("panel", style)
						Globals.draw_layer.add_child(current_panel)
						current_panel.set_owner(layers_root)
						
				#moved - modify objects
				if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					var end = mouse_pos
					if begin.x > end.x and begin.y > end.y:
						current_panel.set_begin(end)
						current_panel.set_end(begin)
					elif begin.x > end.x:
						current_panel.set_begin(Vector2(end.x, begin.y))
						current_panel.set_end(Vector2(begin.x, end.y))
					elif begin.y > end.y:
						current_panel.set_begin(Vector2(begin.x, end.y))
						current_panel.set_end(Vector2(end.x, begin.y))
					else:
						current_panel.set_begin(begin)
						current_panel.set_end(end)
					if Input.is_action_pressed("shift"):
						if current_panel.size.x < current_panel.size.y:
							current_panel.size.x = current_panel.size.y
						else:
							current_panel.size.y = current_panel.size.x
					
			if Globals.tool == "lines":
				if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					pressed = event.pressed
					#just pressed - create objects
					if pressed:
						current_rect = ColorRect.new()
						current_rect.mouse_filter = Control.MOUSE_FILTER_PASS
						current_rect.color = Color(0,0,0,0)
						current_rect.set_meta("polygon", true)
						current_line = Line2D.new()
						current_line.default_color = Globals.colorLines
						current_line.width = Globals.lineWidth
						Globals.draw_layer.add_child(current_rect)
						current_rect.set_owner(layers_root)
						current_rect.add_child(current_line)
						current_line.set_owner(layers_root)
						var pos = mouse_pos
						min_max_x_y = Vector4(pos.x, pos.y, pos.x, pos.y)
						current_line.add_point(pos)
				#moved - modify objects
				if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					var pos = mouse_pos
					if min_max_x_y.x > pos.x: #min x
						min_max_x_y.x = pos.x
					if min_max_x_y.y > pos.y: #min y
						min_max_x_y.y = pos.y
					if min_max_x_y.z < pos.x: #max x
						min_max_x_y.z = pos.x
					if min_max_x_y.w < pos.y: #max y
						min_max_x_y.w = pos.y
					current_line.add_point(pos)
					
			if Globals.tool == "circle":
				if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					pressed = event.pressed
					#just pressed - create objects
					if pressed:
						current_ellipse = CustomEllipse.new()
						current_ellipse.mouse_filter = Control.MOUSE_FILTER_PASS
						current_ellipse.set_meta("polygon", true)
						begin = mouse_pos
						current_ellipse.set_begin(begin)
						current_ellipse.set_end(begin)
						Globals.draw_layer.add_child(current_ellipse)
						current_ellipse.set_owner(layers_root)
				#moved - modify objects
				if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					var end = mouse_pos
					if begin.x > end.x and begin.y > end.y:
						current_ellipse.set_begin(end)
						current_ellipse.set_end(begin)
					elif begin.x > end.x:
						current_ellipse.set_begin(Vector2(end.x, begin.y))
						current_ellipse.set_end(Vector2(begin.x, end.y))
					elif begin.y > end.y:
						current_ellipse.set_begin(Vector2(begin.x, end.y))
						current_ellipse.set_end(Vector2(end.x, begin.y))
					else:
						current_ellipse.set_begin(begin)
						current_ellipse.set_end(end)
					if Input.is_action_pressed("shift"):
						current_ellipse.size.x = current_ellipse.size.y
					current_ellipse.queue_redraw()
					
			if Globals.tool == "text":
				if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					pressed = event.pressed
					#just pressed - create objects
					if pressed:
						#detect if creating new, or editing old
						var lines_children = Globals.draw_layer.get_children()
						var found = 0 #0 nothing | 1 label | 2 textedit
						for x in range(lines_children.size()):
							var child = lines_children[-x-1]
							if child.is_class("Label") or child.is_class("TextEdit"):
								if child.position.x <= mouse_pos.x and child.position.y <= mouse_pos.y:
									if child.position.x + child.size.x*child.scale.x >= mouse_pos.x:
										if child.position.y + child.size.y*child.scale.y >= mouse_pos.y:
											if child.is_class("Label"):
												found = 1
												current_label = child
												break
											#clicked on existing
											found = 2
											break
											
						#didn't click on existing
						if found == 0:
							current_label = Label.new()
							current_label.mouse_filter = Control.MOUSE_FILTER_PASS
							current_label.set_position(mouse_pos)
							if Globals.fontName != "default":
								current_label.add_theme_font_override(Globals.fontName, Globals.font)
							current_label.add_theme_font_size_override(Globals.fontName, Globals.fontSize)
							current_label.add_theme_color_override(Globals.fontName, Globals.fontColor)
							current_label.text = "text"
							Globals.draw_layer.add_child(current_label)
							current_label.set_owner(layers_root)
						#didn't click on existing textedit
						if found != 2:
							current_textedit = TextEdit.new()
							current_textedit.position = current_label.position
							current_textedit.text = current_label.text
							current_label.text = ""
							current_textedit.size = current_textedit.get_theme_font("normal_font").get_multiline_string_size(current_textedit.text)
							current_textedit.scroll_fit_content_height = true
							current_textedit.connect("focus_exited", _text_edit_finished)
							current_textedit.connect("text_changed", _text_edit_text_changed)
							Globals.draw_layer.add_child(current_textedit)
							current_textedit.set_owner(layers_root)
							current_textedit.grab_focus()
							currently_editing_textedit = current_textedit
							currently_editing_label = current_label
				#moved - modify objects
				if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					return
					
			if Globals.tool == "measure":
				if Globals.measureTool == 1: #measure line
					if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						pressed = event.pressed
						#just pressed - create objects
						if pressed:
							current_line = Line2D.new()
							current_line.material = unshaded_material #ignore lighting
							current_line.default_color = Globals.colorLines
							current_line.width = min(Globals.lineWidth,3)
							Globals.draw_layer.add_child(current_line)
							current_line.set_owner(layers_root)
							current_measure.append(current_line)
							current_line.add_point(mouse_pos)
							current_line.add_point(mouse_pos)
							current_rect = ColorRect.new()
							current_rect.mouse_filter = Control.MOUSE_FILTER_PASS
							current_rect.set_size(Vector2(0,0))
							current_label = Label.new()
							current_label.material = unshaded_material #ignore lighting
							current_label.mouse_filter = Control.MOUSE_FILTER_PASS
							current_line.add_child(current_rect)
							current_rect.set_owner(layers_root)
							current_rect.add_child(current_label)
							current_label.set_owner(layers_root)
							current_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
					#moved - modify objects
					if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						current_line.set_point_position(1, mouse_pos)
						current_label.text = str(snapped(current_line.get_point_position(0).distance_to(current_line.get_point_position(1))/Globals.map.grid_size, 0.01) * Globals.map.unit_size) + " " + Globals.map.unit
						current_rect.set_position(mouse_pos)
						current_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
						print(current_label.anchors_preset)
						
				if Globals.measureTool == 2: #measure circle
					if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						pressed = event.pressed
						#just pressed - create objects
						if pressed:
							begin = mouse_pos
							current_circle = CustomCircle.new()
							current_circle.material = unshaded_material #ignore lighting
							current_circle.mouse_filter = Control.MOUSE_FILTER_PASS
							current_circle.set_position(mouse_pos)
							current_circle.center = begin
							Globals.draw_layer.add_child(current_circle)
							current_circle.set_owner(layers_root)
							current_measure.append(current_circle)
							current_rect = ColorRect.new()
							current_rect.mouse_filter = Control.MOUSE_FILTER_PASS
							current_rect.set_size(Vector2(0,0))
							current_label = Label.new()
							current_label.material = unshaded_material #ignore lighting
							current_label.mouse_filter = Control.MOUSE_FILTER_PASS
							Globals.draw_layer.add_child(current_rect)
							current_rect.set_owner(layers_root)
							current_measure.append(current_rect)
							current_rect.add_child(current_label)
							current_label.set_owner(layers_root)
					#moved - modify objects
					if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						current_circle.radius = begin.distance_to(mouse_pos)
						current_label.text = str(snapped(begin.distance_to(mouse_pos)/Globals.map.grid_size, 0.01) * Globals.map.unit_size) + " " + Globals.map.unit
						current_rect.set_position(mouse_pos)
						current_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
						print("z index: ", current_label.z_index)
						print(current_circle.center, begin)
						print(current_circle.radius, current_circle.size, current_circle.position, mouse_pos)
						
				if Globals.measureTool == 3: #measure angle
					if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						pressed = event.pressed
						#just pressed - create objects
						if pressed:
							begin = mouse_pos
							current_arc = CustomArc.new()
							current_arc.material = unshaded_material #ignore lighting
							current_arc.mouse_filter = Control.MOUSE_FILTER_PASS
							current_arc.set_position(mouse_pos)
							current_arc.center = begin
							current_arc.angle_size = Globals.measureAngle
							Globals.draw_layer.add_child(current_arc)
							current_arc.set_owner(layers_root)
							current_measure.append(current_arc)
							current_rect = ColorRect.new()
							current_rect.mouse_filter = Control.MOUSE_FILTER_PASS
							current_rect.set_size(Vector2(0,0))
							current_label = Label.new()
							current_label.material = unshaded_material #ignore lighting
							current_label.mouse_filter = Control.MOUSE_FILTER_PASS
							Globals.draw_layer.add_child(current_rect)
							current_rect.set_owner(layers_root)
							current_measure.append(current_rect)
							current_rect.add_child(current_label)
							current_label.set_owner(layers_root)
					#moved - modify objects
					if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						current_arc.angle_direction = (mouse_pos - begin).angle()
						print(begin.angle_to(mouse_pos))
						current_arc.radius = begin.distance_to(mouse_pos)
						current_label.text = str(snapped(begin.distance_to(mouse_pos)/Globals.map.grid_size, 0.01) * Globals.map.unit_size) + " " + Globals.map.unit
						current_rect.set_position(mouse_pos)
						current_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
						print(current_arc.center, begin)
						print(current_arc.radius, " ", current_arc.angle_size, " ", current_arc.angle_direction, mouse_pos)
					
			if Globals.tool == "select":
				if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					pressed = event.pressed
					print("selection pressed")
					if mouse_over_tl or mouse_over_tr or mouse_over_bl or mouse_over_br: #scale
						print("mouse_over_bltlbrtr")
						oposite_corner_pos_in_world = null
						selected_scaling = true
						min_max_x_y = Vector4(select_box.position.x, select_box.position.y, select_box.position.x+select_box.size.x, select_box.position.y+select_box.size.y)
						select_pos_org = select_box.position
						select_size_org = select_box.size
						selected_org_scales.clear()
						selected_org_pos.clear()
						for object in selected:
							print(object)
							selected_org_pos.append(object.position)
#							if "character" in object: #character token - rotate only image, not bars
#								selected_org_scales.append(object.get_child(0).scale)
#							else:
							selected_org_scales.append(object.scale)
						return
					elif mouse_over_rotate: #rotate
						print("mouse_over_rotate")
						selected_rotating = true
						if select_box.rotation == 0:
							select_center_pos = select_box.position + select_box.size/2
						else:
							var dis = Vector2(0,0).distance_to(select_box.size/2)
							var ang = Vector2(0,0).angle_to_point(select_box.size)
							select_center_pos = select_box.position + Vector2(dis * cos(ang + select_box.rotation), dis * sin(ang + select_box.rotation))
						select_pos_org = select_box.position
						select_rot_org = select_box.rotation
						selected_org_rots.clear()
						selected_org_pos.clear()
						for object in selected:
							selected_org_pos.append(object.position)
#							if "character" in object: #character token - rotate only image, not bars
#								selected_org_rots.append(object.get_child(0).rotation)
#							else:
							selected_org_rots.append(object.rotation)
						return
					elif mouse_over_selected: #drag
						print("mouse_over_selected")
						selected_dragging = true
						return
					#just pressed - create objects
					elif pressed:
						print("selection creating")
						#remove old select
						if select_box != null:
							select_box.queue_free()
						create_select_box(mouse_pos)
	#					else:
	#						selected.clear()
	#						current_panel = $Select.get_child(0)
	#						begin = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
	#						current_panel.set_begin(begin)
	#						current_panel.set_end(begin)
						selected_creating = true
				#moved - modify objects
				if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					if select_box == null:
						return
					#drag - move objects
					if selected_dragging:
						print("drag")
						var relative_offset = event.relative/get_node("../Camera2D").zoom
						for object in selected:
							object.position += relative_offset
						select_box.position += relative_offset
						return
					#rotate objects
					elif selected_rotating:
						print("rotate")
						var angle = fmod(select_center_pos.angle_to_point(get_global_mouse_position()) + deg_to_rad(90), 2*PI) #angle between pivot and mouse
						print(rad_to_deg(angle))
						select_box.rotation = angle
#						var dis = Vector2(0,0).distance_to(select_box.size/2)
#						var ang = Vector2(0,0).angle_to_point(select_box.size)
#						select_box.pivot_offset = Vector2(dis * cos(select_box.rotation + ang), dis * sin(select_box.rotation + ang))
						var distance = select_center_pos.distance_to(select_box.position)
						var angle_org = select_box.size.angle_to_point(Vector2(0,0))
						print(select_center_pos)
						print("---=====|||||||||||||||||||||||>>>>>>>>>>>>>>>>>>>>>>>>>>>>", select_box.position, rad_to_deg(angle_org), " ", rad_to_deg(angle))
						select_box.position = Vector2(select_center_pos.x + cos(angle_org + angle) * distance, select_center_pos.y + sin(angle_org + angle) * distance)
						var i = 0
						print(select_box.position)
						for object in selected:
							print("rot: ", object.rotation)
							distance = select_center_pos.distance_to(selected_org_pos[i])
							angle_org = select_center_pos.angle_to_point(selected_org_pos[i])
							object.position = Vector2(select_center_pos.x + cos(angle_org + angle - select_rot_org) * distance, select_center_pos.y + sin(angle_org + angle - select_rot_org) * distance)
							object.rotation = fmod(selected_org_rots[i] + angle - select_rot_org, 2*PI)
							i += 1
							#if object is token - update UI
							if "character" in object.get_parent():
								object.get_parent().UI_set_position()
						return
					#scale objects
					elif selected_scaling:
						print("scale")
						var mouse_pos_rot #position of mouse in select_box rotation plane
						if select_box.rotation == 0:
							mouse_pos_rot = mouse_pos
						else:
							var distance = select_box.position.distance_to(mouse_pos)
							var angle = select_box.position.angle_to_point(mouse_pos)
							mouse_pos_rot = Vector2(select_box.position.x + cos(- select_box.rotation + angle) * distance, select_box.position.y + sin(- select_box.rotation + angle) * distance)
							mouse_pos_rot = mouse_pos_rot
						if mouse_over_tl: #scale
							if mouse_pos_rot.x < select_box.position.x + select_box.size.x and mouse_pos_rot.y < select_box.position.y + select_box.size.y: #tl
#								var scal = (select_box.size-relative_offset)/select_box.size
#								select_box.set_begin(Vector2((select_box.get_begin().x+relative_offset.x), (select_box.get_begin().y+relative_offset.y)))
								if select_box.rotation == 0:
									select_box.set_begin(mouse_pos_rot)
								else:
									if (oposite_corner_pos_in_world == null):
										var distance = Vector2(0,0).distance_to(select_box.size)
										var angle = Vector2(0,0).angle_to_point(select_box.size)
										oposite_corner_pos_in_world = Vector2(select_box.position.x + distance * cos(angle + select_box.rotation), select_box.position.y + distance * sin(angle + select_box.rotation))
									select_box.set_begin(mouse_pos)
									var distance = mouse_pos.distance_to(oposite_corner_pos_in_world)
									var angle = mouse_pos.angle_to_point(oposite_corner_pos_in_world)
									var new_location_in_local = Vector2(select_box.position.x + distance * cos(angle - select_box.rotation), select_box.position.y + distance * sin(angle - select_box.rotation))
									select_box.set_end(new_location_in_local)
								scale_items()
							elif mouse_pos_rot.x < select_box.position.x + select_box.size.x: #bl
								flip_y = !flip_y
								mouse_over_bl = true
								mouse_over_tl = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							elif mouse_pos_rot.y < select_box.position.y + select_box.size.y: #tr
								flip_x = !flip_x
								mouse_over_tr = true
								mouse_over_tl = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							else: #br
								flip_x = !flip_x
								flip_y = !flip_y
								mouse_over_tl = true
								mouse_over_tl = false
						elif mouse_over_bl: #scale
							if mouse_pos_rot.x < select_box.position.x + select_box.size.x and mouse_pos_rot.y > select_box.position.y: #bl
								if select_box.rotation == 0:
									select_box.set_begin(Vector2(mouse_pos_rot.x, select_box.position.y))
									select_box.size.y = mouse_pos_rot.y - select_box.position.y
								else:
									if (oposite_corner_pos_in_world == null): #if new - reset upon new scale
										var distance = select_box.size.x
										var angle = 0
										oposite_corner_pos_in_world = Vector2(select_box.position.x + distance * cos(angle + select_box.rotation), select_box.position.y + distance * sin(angle + select_box.rotation))
									#intersect lines from mouse_pos and oposite_corner_pos_in_world to get new position
									select_box.position = Geometry2D.line_intersects_line(oposite_corner_pos_in_world, Vector2.LEFT.rotated(select_box.rotation), mouse_pos, Vector2.UP.rotated(select_box.rotation))
									select_box.size = Vector2(select_box.position.distance_to(oposite_corner_pos_in_world), select_box.position.distance_to(mouse_pos))
								scale_items()
							elif mouse_pos_rot.x < select_box.position.x + select_box.size.x: #tl
								flip_y = !flip_y
								mouse_over_tl = true
								mouse_over_bl = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							elif mouse_pos_rot.y > select_box.position.y: #br
								flip_x = !flip_x
								mouse_over_br = true
								mouse_over_bl = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							else: #tr
								flip_x = !flip_x
								flip_y = !flip_y
								mouse_over_tr = true
								mouse_over_bl = false
						elif mouse_over_tr: #scale
							if mouse_pos_rot.x > select_box.position.x and mouse_pos_rot.y < select_box.position.y + select_box.size.y: #tr
#								var scal = Vector2((select_box.size.x+relative_offset.x)/select_box.size.x, (select_box.size.y-relative_offset.y)/select_box.size.y)
#								select_box.size.x += relative_offset.x
#								select_box.set_begin(Vector2(select_pos.x, select_box.get_begin().y+relative_offset.y))
								if select_box.rotation == 0:
									select_box.set_begin(Vector2(select_box.position.x, mouse_pos_rot.y))
									select_box.size.x = mouse_pos_rot.x - select_box.position.x
								else:
									if (oposite_corner_pos_in_world == null):
										var distance = select_box.size.y
										var angle = deg_to_rad(90)
										oposite_corner_pos_in_world = Vector2(select_box.position.x + distance * cos(angle + select_box.rotation), select_box.position.y + distance * sin(angle + select_box.rotation))
									#intersect lines from mouse_pos and oposite_corner_pos_in_world to get new position
									select_box.position = Geometry2D.line_intersects_line(oposite_corner_pos_in_world, Vector2.UP.rotated(select_box.rotation), mouse_pos, Vector2.LEFT.rotated(select_box.rotation))
									select_box.size = Vector2(select_box.position.distance_to(mouse_pos), select_box.position.distance_to(oposite_corner_pos_in_world))
								scale_items()
							elif mouse_pos_rot.x > select_box.position.x: #br
								flip_y = !flip_y
								mouse_over_br = true
								mouse_over_tr = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							elif mouse_pos_rot.y < select_box.position.y + select_box.size.y: #tl
								flip_x = !flip_x
								mouse_over_tl = true
								mouse_over_tr = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							else: #bl
								flip_x = !flip_x
								flip_y = !flip_y
								mouse_over_bl = true
								mouse_over_tr = false
						elif mouse_over_br: #scale
							if select_box.rotation == 0:
								mouse_pos_rot = mouse_pos
							else:
								var distance = select_box.position.distance_to(mouse_pos)
								var angle = select_box.position.angle_to_point(mouse_pos)
								mouse_pos_rot = Vector2(select_box.position.x + cos(- select_box.rotation + angle) * distance, select_box.position.y + sin(- select_box.rotation + angle) * distance)
							if (mouse_pos_rot.x > select_box.position.x) and (mouse_pos_rot.y > select_box.position.y): #br
								select_box.set_end(mouse_pos_rot)
								scale_items()
							elif mouse_pos_rot.x > select_box.position.x : #tr
								print("entering tr")
								flip_y = !flip_y
								mouse_over_tr = true
								mouse_over_br = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							elif mouse_pos_rot.y > select_box.position.y: #bl
								print("entering bl")
								flip_x = !flip_x
								mouse_over_bl = true
								mouse_over_br = false
								for object in selected:
									if select_box.rotation != object.rotation:
										object.rotation = -object.rotation
							else: #tl
								flip_x = !flip_x
								flip_y = !flip_y
								mouse_over_tl = true
								mouse_over_br = false
						return
					#drawing selection box - update size
					else:
						var end = mouse_pos
						if begin.x > end.x and begin.y > end.y:
							select_box.set_begin(end)
							select_box.set_end(begin)
						elif begin.x > end.x:
							select_box.set_begin(Vector2(end.x, begin.y))
							select_box.set_end(Vector2(begin.x, end.y))
						elif begin.y > end.y:
							select_box.set_begin(Vector2(begin.x, end.y))
							select_box.set_end(Vector2(end.x, begin.y))
						else:
							select_box.set_begin(begin)
							select_box.set_end(end)
						if Input.is_action_pressed("shift"):
							if select_box.size.x < select_box.size.y:
								select_box.size.x = select_box.size.y
							else:
								select_box.size.y = select_box.size.x
								
	elif event is InputEventKey:
		print("key pressed")
		if Input.is_action_just_pressed("Delete") or Input.is_action_just_pressed("ui_cut"): #delete or cut selection
			if Input.is_action_just_pressed("ui_cut"):
				copy_to_clipboard()
			for child in selected: #delete
				if "character" in child.get_parent(): #character token
					child = child.get_parent()
					Globals.new_map.remove_token(child)
				if child.has_meta("light"):
					var light = get_object_light(child)
					if light != null:
						light.queue_free()
				child.queue_free()
			#remove select box
			if select_box != null:
				select_box.queue_free()
				
			#resetting select box state variables
			selected_tokens.clear()
			selected.clear()
			mouse_over_selected = false
			selected_creating = false
			selected_scaling = false
			selected_rotating = false
			mouse_over_tl = false
			mouse_over_bl = false
			mouse_over_tr = false
			mouse_over_br = false
			mouse_over_rotate = false
			
		elif Input.is_action_just_pressed("Escape"): #go back to map selection
			get_tree().change_scene_to_file("res://scenes/Maps.tscn")
			
		elif Input.is_action_just_pressed("I-pressed"): #open inventory TODO - get character from token
			print("released I")
			if not selected.is_empty():
				print("released I - selected not empty")
				var inv_sheet = inventory_sheet.instantiate()
				inv_sheet.position = get_viewport().get_mouse_position()
				inv_sheet.selected = selected
				Globals.windows.add_child(inv_sheet)
				
		if Input.is_action_just_pressed("ui_copy"):
			copy_to_clipboard()
				
		if Input.is_action_just_pressed("ui_paste"):
			var c = Globals.clipboard_characters.size() - 1 #index for character array
			var l = Globals.clipboard_lights.size() - 1 #index for light array
			for i in range(Globals.clipboard_objects.size()-1, -1, -1): #iterate backwards
				var new_object = Globals.clipboard_objects[i].duplicate(5)
				if "character" in new_object: #character data not duplicated - needs to be set
					new_object.character = Globals.clipboard_characters[c]
					Globals.map.add_token(new_object)
					c -= 1	
				Globals.draw_layer.add_child(new_object)
				if new_object.has_meta("light"): #light is a sibling of object - needs to be stored separately
					var light = Globals.clipboard_lights[l].duplicate(5)
					l -= 1
					new_object.add_sibling(light)
					var remote = get_object_light_remote(new_object)
					remote.remote_path = remote.get_path_to(light)

func copy_to_clipboard():
	for object in Globals.clipboard_objects: # free old clipboard
		object.queue_free()
	for light in Globals.clipboard_lights: # free old clipboard
		light.queue_free()
	Globals.clipboard_objects.clear()
	Globals.clipboard_characters.clear()
	Globals.clipboard_lights.clear()
	for object in selected: #fill clipboard
		if "character" in object: #tokenpolygon - get token
			object = object.get_parent()
			#character data not duplicated - needs to be saved
			if object.character.singleton:
				Globals.clipboard_characters.append(object.character)
			else:
				Globals.clipboard_characters.append(object.character.duplicate(true))
		if object.has_meta("light"): #light is a sibling of object - needs to be stored separately
			var light = get_object_light(object).duplicate(5)
			Globals.clipboard_lights.append(light)
		Globals.clipboard_objects.append(object.duplicate(5))


func get_clicked(mouse_position: Vector2):
	var lines_children = Globals.draw_layer.get_children()
	lines_children.reverse()
	var array_list = [lines_children]
	if Globals.select_recursive:
		var treeitem_array = layer_tree.get_descendants(layer_tree.get_selected())
		for treeitem in treeitem_array:
			lines_children = treeitem.get_meta("draw_layer").get_children()
			lines_children.reverse()
			array_list.append(lines_children)
	for array in array_list:
		for child in array:
			if "character" in child: #if character token
				child = child.get_child(0)
			if child.is_class("Node2D"): #inherits from Node2D
				continue
#					print("mouse pos: ", mouse_position)
#					print("pos: ", child.position)
#					print("size: ", child.size)
#					print("scale: ", child.scale)
			if child.rotation == 0:
				if child.scale.x < 0 and child.scale.y < 0: #flipped object
					if child.position.x >= mouse_position.x and child.position.y >= mouse_position.y:
						if child.position.x + child.size.x*child.scale.x <= mouse_position.x:
							if child.position.y + child.size.y*child.scale.y <= mouse_position.y:
								return child
				elif child.scale.x < 0: #flipped x
					if child.position.x >= mouse_position.x and child.position.y <= mouse_position.y:
						if child.position.x + child.size.x*child.scale.x <= mouse_position.x:
							if child.position.y + child.size.y*child.scale.y >= mouse_position.y:
								return child
				elif child.scale.y < 0: #flipped y
					if child.position.x <= mouse_position.x and child.position.y >= mouse_position.y:
						if child.position.x + child.size.x*child.scale.x >= mouse_position.x:
							if child.position.y + child.size.y*child.scale.y <= mouse_position.y:
								return child
				else: #not flipped
					if child.position.x <= mouse_position.x and child.position.y <= mouse_position.y:
						if child.position.x + child.size.x*child.scale.x >= mouse_position.x:
							if child.position.y + child.size.y*child.scale.y >= mouse_position.y:
								return child
			else: #calculate with rotation
				var diagonal = Vector2(0,0).distance_to(child.size * child.scale)
				var angle = Vector2(0,0).angle_to_point(child.size * child.scale)
				var top_left = child.position
				var top_right = Vector2(child.position.x + child.size.x * child.scale.x * cos(child.rotation), child.position.y + child.size.x * child.scale.x * sin(child.rotation))
				var bottom_right = Vector2(child.position.x + diagonal * cos(angle + child.rotation), child.position.y + diagonal * sin(angle + child.rotation))
				var bottom_left = Vector2(child.position.x + child.size.y * child.scale.y * cos(deg_to_rad(90) + child.rotation), child.position.y + child.size.y * child.scale.y * sin(deg_to_rad(90) + child.rotation))
				print(top_left, top_right, bottom_right, bottom_left)
				if Geometry2D.is_point_in_polygon(mouse_position, PackedVector2Array([top_left, top_right, bottom_right, bottom_left])):
					return child
	return null

#sets select box size to selection size, selects tokens
func select_objects():
	if select_box == null:
		create_select_box(mouse_pos)
	if selected.size() == 1:
		print("one item")
		var s = selected[0]
		select_box.rotation = s.rotation
		var vect = s.size*s.scale #size cannot be negative
		if vect.x < 0:
			vect.x = vect.x * -1
		if vect.y < 0:
			vect.y = vect.y * -1
		select_box.size = vect
		if s.scale.x < 0 and s.scale.y < 0: #object flipped
			var distance = Vector2(0,0).distance_to(s.size * s.scale)
			var angle = Vector2(0,0).angle_to_point(s.size * s.scale) + s.rotation
			print("dis: ", distance, " ang: ", angle)
			select_box.position = Vector2(s.position.x + distance * cos(angle), s.position.y + distance * sin(angle))
		elif s.scale.x < 0: #object x flipped
			var distance = s.size.x * s.scale.x
			var angle = s.rotation
			print("dis: ", distance, " ang: ", angle)
			select_box.position = Vector2(s.position.x + distance * cos(angle), s.position.y + distance * sin(angle))
		elif s.scale.y < 0: #object y flipped
			var distance = s.size.y * s.scale.y
			var angle = deg_to_rad(90) + s.rotation
			print("dis: ", distance, " ang: ", angle)
			select_box.position = Vector2(s.position.x + distance * cos(angle), s.position.y + distance * sin(angle))
		else: #object not flipped
			select_box.position = s.position
		
	else:
		print(min_max_x_y)
		select_box.set_begin(Vector2(min_max_x_y.x, min_max_x_y.y))
		select_box.set_end(Vector2(min_max_x_y.z, min_max_x_y.w))
		select_box.rotation = 0
	#				select_box.pivot_offset = Vector2(min_x + select_box.size.x/2, min_y + select_box.size.y/2)

	for token in selected_tokens: #reset unselected token opacity and UI visibility
		token.unselect()
	selected_tokens.clear()
	for object in selected: #set selected token opacity and UI visibility
		if "character" in object: #token
			var token = object.get_parent()
			selected_tokens.append(token)
			token.select()
	Globals.action_bar.fill_action_bar(selected_tokens) #fill action bar based on selected tokens
	if selected.is_empty():
		select_box.queue_free()
		return
			
	#control points - handles
	create_handle(Control.PRESET_TOP_LEFT, 15)
	current_panel.connect("mouse_entered", _tl_handle_mouse_entered)
	current_panel.connect("mouse_exited", _tl_handle_mouse_exited)
	create_handle(Control.PRESET_BOTTOM_LEFT, 15)
	current_panel.connect("mouse_entered", _bl_handle_mouse_entered)
	current_panel.connect("mouse_exited", _bl_handle_mouse_exited)
	create_handle(Control.PRESET_TOP_RIGHT, 15)
	current_panel.connect("mouse_entered", _tr_handle_mouse_entered)
	current_panel.connect("mouse_exited", _tr_handle_mouse_exited)
	create_handle(Control.PRESET_BOTTOM_RIGHT, 15)
	current_panel.connect("mouse_entered", _br_handle_mouse_entered)
	current_panel.connect("mouse_exited", _br_handle_mouse_exited)
	create_handle(Control.PRESET_CENTER_TOP, 20)
	current_panel.connect("mouse_entered", _rotate_handle_mouse_entered)
	current_panel.connect("mouse_exited", _rotate_handle_mouse_exited)
	
	
func _on_select_mouse_entered():
	print("mouse over selected")
	mouse_over_selected = true
	
func _on_select_mouse_exited():
	mouse_over_selected = false
	
#scales item of selectbox based on its changes
func scale_items():
	var scal = select_box.size/select_size_org
	var i = 0
	for object in selected:
		print("object scale: ", object.scale, selected_org_scales[i])
#		var token = null #is character token - flip image, not object
#		var char_offset = Vector2(0,0) #offset for character token - image is in different global location than token object
#		if "character" in object: #character token - sca only image, not bars
#			token = object.get_child(0)
#			object.rotation = token.rotation
#			object.scale = token.scale
#			print("scale at start: ", object.scale, token.rotation)
#			var distance = Vector2(0,0).distance_to(object.size * object.scale / 2)
#			var angle = (object.size * object.scale).angle_to_point(Vector2(0,0)) + object.rotation
#			char_offset = object.size * object.scale / 2 + Vector2(distance * cos(angle), distance * sin(angle))
		if (object.rotation == 0 and select_box.rotation == 0): #scale without rotation - faster
			object.scale = scal * selected_org_scales[i]
			if flip_x and flip_y:
				object.scale *= -1
				object.position = (select_pos_org - selected_org_pos[i] + select_size_org) / select_size_org * select_box.size + select_box.position
			elif flip_x:
				object.scale.x *= -1
				object.position.x = (select_pos_org.x - selected_org_pos[i].x + select_size_org.x) / select_size_org.x * select_box.size.x + select_box.position.x
				object.position.y = (selected_org_pos[i].y - select_pos_org.y) / select_size_org.y * select_box.size.y + select_box.position.y	
			elif flip_y:
				object.scale.y *= -1
				object.position.x = (selected_org_pos[i].x - select_pos_org.x) / select_size_org.x * select_box.size.x + select_box.position.x
				object.position.y = (select_pos_org.y - selected_org_pos[i].y + select_size_org.y) / select_size_org.y * select_box.size.y + select_box.position.y
			else:
				object.position = (selected_org_pos[i] - select_pos_org) / select_size_org * select_box.size + select_box.position
		else: #scale with rotation - not great, proper implementation would require nesting inside another component - one for rotate, other for scale, and would lead to permanent deformation
			print(object.rotation, " ", select_box.rotation)
			if object.rotation == select_box.rotation and selected.size() == 1: #one item scale with select_box
				object.scale = scal * selected_org_scales[i]
				print("one object", object.scale)
			else: #more items scale with lesser of select_box changes - works decently well
				print("multiple objects", object.scale)
				var scal_square = scal
				if scal_square.x < scal_square.y:
					scal_square.y = scal_square.x
				else:
					scal_square.x = scal_square.y
				object.scale = scal_square * selected_org_scales[i]
			# ==== scaling objects based on flip state of select_box ====
			if flip_x and flip_y:
				print("flip xy")
				object.scale = -object.scale #flip xy
				#get difference between object positions
				var difference = (selected_org_pos[i] - select_pos_org)
				var distance = Vector2(0,0).distance_to(difference)
				var angle = Vector2(0,0).angle_to_point(difference)
				print("angle: ", rad_to_deg(angle), " distance: ", distance, " difference: ", difference)
				#rotate diference based on select_box rotation:
				difference = Vector2(distance * cos(angle - select_box.rotation), distance * sin(angle - select_box.rotation)) * scal
				difference = -difference #flip xy in difference
				distance = Vector2(0,0).distance_to(difference)
				angle = Vector2(0,0).angle_to_point(difference) + select_box.rotation #rotate object back based on select_box rotation
				print("rot angle: ", rad_to_deg(angle), " distance: ", distance, " difference: ", difference)
				var offset_distance = Vector2(0,0).distance_to(select_box.size)
				var offset_angle = Vector2(0,0).angle_to_point(select_box.size) + select_box.rotation
				var offset = Vector2(offset_distance * cos(offset_angle), offset_distance * sin(offset_angle))
				object.position = Vector2(select_box.position.x + offset.x + distance * cos(angle), select_box.position.y + offset.y + distance * sin(angle))
				print("selectbox_pos: ", select_box.position, " offset: ", offset, " object_pos: ", object.position)
			elif flip_x:
				print("flip x")
				object.scale.x = -object.scale.x #flip x
				#get difference between object positions
				var difference = (selected_org_pos[i] - select_pos_org)
				var distance = Vector2(0,0).distance_to(difference)
				var angle = Vector2(0,0).angle_to_point(difference)
				print("angle: ", rad_to_deg(angle), " distance: ", distance, " difference: ", difference)
				#rotate diference based on select_box rotation:
				difference = Vector2(distance * cos(angle - select_box.rotation), distance * sin(angle - select_box.rotation)) * scal
				difference.x = -difference.x #flip x in difference
				distance = Vector2(0,0).distance_to(difference)
				angle = Vector2(0,0).angle_to_point(difference) + select_box.rotation #rotate object back based on select_box rotation
				print("rot angle: ", rad_to_deg(angle), " distance: ", distance, " difference: ", difference)
				var offset = Vector2(select_box.size.x * cos(select_box.rotation), select_box.size.x * sin(select_box.rotation))
				object.position = Vector2(select_box.position.x + offset.x + distance * cos(angle), select_box.position.y + offset.y + distance * sin(angle))
				print("selectbox_pos: ", select_box.position, " offset: ", offset, " object_pos: ", object.position)
			elif flip_y:
				print("flip y")
				object.scale.y = -object.scale.y #flip y
				#get difference between object positions
				var difference = (selected_org_pos[i] - select_pos_org)
				var distance = Vector2(0,0).distance_to(difference)
				var angle = Vector2(0,0).angle_to_point(difference)
				print("angle: ", rad_to_deg(angle), " distance: ", distance, " difference: ", difference)
				#rotate diference based on select_box rotation:
				difference = Vector2(distance * cos(angle - select_box.rotation), distance * sin(angle - select_box.rotation)) * scal
				difference.y = -difference.y #flip y in difference
				distance = Vector2(0,0).distance_to(difference)
				angle = Vector2(0,0).angle_to_point(difference) + select_box.rotation #rotate object back based on select_box rotation
				print("rot angle: ", rad_to_deg(angle), " distance: ", distance, " difference: ", difference)
				var offset = Vector2(select_box.size.y * cos(select_box.rotation + deg_to_rad(90)), select_box.size.y * sin(select_box.rotation + deg_to_rad(90)))
				object.position = Vector2(select_box.position.x + offset.x + distance * cos(angle), select_box.position.y + offset.y + distance * sin(angle))
				print("selectbox_pos: ", select_box.position, " offset: ", offset, " object_pos: ", object.position)
			else:
				#get difference between object positions
				var difference = (selected_org_pos[i] - select_pos_org)
				var distance = Vector2(0,0).distance_to(difference)
				var angle = Vector2(0,0).angle_to_point(difference)
				#rotate diference based on select_box rotation:
				difference = Vector2(distance * cos(angle - select_box.rotation), distance * sin(angle - select_box.rotation)) * scal
				distance = Vector2(0,0).distance_to(difference)
				angle = Vector2(0,0).angle_to_point(difference) + select_box.rotation #rotate object back based on select_box rotation
				object.position = Vector2(select_box.position.x + distance * cos(angle), select_box.position.y + distance * sin(angle))
		i += 1
		#if object is token - update UI
		if "character" in object.get_parent():
			object.get_parent().UI_set_position()
	
#creates handle for selection box
#preset - anchor point
#s - size
func create_handle(preset: Control.LayoutPreset, s: float):
	current_panel = Panel.new()
	current_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	current_panel.position = Vector2(-s/2,-s/2)
	current_panel.size = Vector2(s,s)
	current_panel.pivot_offset = Vector2(s/2,s/2)
	current_panel.set_anchors_preset(preset)
	current_panel.scale = Vector2(1/$"../Camera2D".zoom.x, 1/$"../Camera2D".zoom.y)
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color.BLACK
	style.set_border_width_all(s/5)
	style.set_corner_radius_all(s)
	current_panel.add_theme_stylebox_override("panel", style)
	current_panel.material = unshaded_material
	select_box.add_child(current_panel)
	
func _tl_handle_mouse_entered():
	if !selected_scaling:
		mouse_over_tl = true

func _tl_handle_mouse_exited():
	if !selected_scaling:
		mouse_over_tl = false
	
func _tr_handle_mouse_entered():
	if !selected_scaling:
		mouse_over_tr = true

func _tr_handle_mouse_exited():
	if !selected_scaling:
		mouse_over_tr = false

func _bl_handle_mouse_entered():
	if !selected_scaling:
		mouse_over_bl = true

func _bl_handle_mouse_exited():
	if !selected_scaling:
		mouse_over_bl = false
	
func _br_handle_mouse_entered():
	if !selected_scaling:
		mouse_over_br = true

func _br_handle_mouse_exited():
	if !selected_scaling:
		mouse_over_br = false
		
func _rotate_handle_mouse_entered():
	if !selected_scaling:
		mouse_over_rotate = true

func _rotate_handle_mouse_exited():
	if !selected_scaling:
		mouse_over_rotate = false

#drag and drop images
func on_files_dropped(files):
	print(files)
	for file in files:
		var tex = ImageTexture.new()
		var img = Image.new()
		var err = img.load(file)
		if err != OK:
			print("import failed")
			return
		else:
			print("import done")
			print(img.get_size())
		tex.set_image(img)
		current_panel = Panel.new()
		current_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var begin = get_viewport().get_mouse_position()
		current_panel.set_begin(begin)
		current_panel.set_end(begin + Vector2(50,50))
		var style = StyleBoxTexture.new()
		style.texture = tex
		current_panel.add_theme_stylebox_override("panel", style)
		Globals.draw_layer.add_child(current_panel)
		current_panel.set_owner(layers_root)
		
		
func _text_edit_finished():
	selected.clear()
	currently_editing_label.text = currently_editing_textedit.text
	#lines.remove_child(currently_editing_textedit)
	currently_editing_textedit.queue_free()
	print("free")
	if currently_editing_label.text.is_empty():
		#lines.remove_child(currently_editing_label)
		currently_editing_label.queue_free()
		print("free")
	
func _text_edit_text_changed():
	current_textedit.size = current_textedit.get_theme_font("normal_font").get_multiline_string_size(current_textedit.text) + Vector2(20, current_textedit.get_theme_font("normal_font").get_height(Globals.fontSize))
	
func _on_transform_signal(index, value):
	if index == 0:
		for object in selected:
			object.position.x = value
	if index == 1:
		for object in selected:
			object.position.y = value
	if index == 2:
		for object in selected:
			object.size.x = value
			print(object)
			if object.name == "TokenPolygon": #token - need to update polygon points
				object.scale_shape_to_size()
				object.get_parent().UI_set_position()
	if index == 3:
		for object in selected:
			object.size.y = value
			print(object)
			if object.name == "TokenPolygon": #token - need to update polygon points
				object.scale_shape_to_size()
				object.get_parent().UI_set_position()
	if index == 4:
		for object in selected:
			object.scale.x = value
	if index == 5:
		for object in selected:
			object.scale.y = value
	if index == 6:
		for object in selected:
			object.rotation = value
			
func _on_light_signal(index, value):
	if index == 0:
		for object in selected:
			object.position.x = value
	if index == 1:
		for object in selected:
			object.position.y = value
	if index == 2:
		for object in selected:
			object.size.x = value
			print(object)
			if object.name == "TokenPolygon": #token - need to update polygon points
				object.scale_shape_to_size()
				object.get_parent().UI_set_position()
	if index == 3:
		for object in selected:
			object.size.y = value
			print(object)
			if object.name == "TokenPolygon": #token - need to update polygon points
				object.scale_shape_to_size()
				object.get_parent().UI_set_position()
	if index == 4:
		for object in selected:
			object.scale.x = value
	if index == 5:
		for object in selected:
			object.scale.y = value
	if index == 6:
		for object in selected:
			object.rotation = value
			
#editing object in tool panel
func _on_object_change_signal(index, value):
	#transforms
	if index == 0: #position x
		for object in selected:
			object.position.x = value
	if index == 1: #position y
		for object in selected:
			object.position.y = value
	if index == 2: #size x
		for object in selected:
			object.size.x = value
			if object.name == "TokenPolygon": #token size - need to update polygon points
				object.scale_shape_to_size()
				object.get_parent().UI_set_position()
	if index == 3: #size y
		for object in selected:
			object.size.y = value
			if object.name == "TokenPolygon": #token size - need to update polygon points
				object.scale_shape_to_size()
				object.get_parent().UI_set_position()
	if index == 4: #scale x
		for object in selected:
			object.scale.x = value
	if index == 5: #scale y
		for object in selected:
			object.scale.y = value
	if index == 6: #rotation
		for object in selected:
			object.rotation = value
			
	#light
	if index == 10: #light enable
		if value == true:
			for object in selected:
				create_or_enable_light(object)
		else:
			for object in selected:
				disable_light(object)
	if index == 11: #light offset x
		for object in selected:
			if object.has_meta("light"): #changing offset in light does not change light casting point - requires changing position
				var light_remote = get_object_light_remote(object)
				if light_remote != null:
					light_remote.position.x = value
	if index == 12: #light offset y
		for object in selected:
			if object.has_meta("light"): #changing offset in light does not change light casting point - requires changing position
				var light_remote = get_object_light_remote(object)
				if light_remote != null:
					light_remote.position.y = value
			
	if index == 13: #light texture resolution
		for object in selected:
			if object.has_meta("light"):
				var light = get_object_light(object)
				if light != null:
					light.texture.height = value
					light.texture.width = value
	if index == 14: #light radius
		for object in selected:
			if object.has_meta("light"):
				var light = get_object_light(object)
				if light != null:
					light.texture_scale = value/light.texture.get_height()*2
	if index == 15: #light color
		for object in selected:
			if object.has_meta("light"):
				var light = get_object_light(object)
				if light != null:
					light.color = value
	if index == 16: #light energy
		for object in selected:
			if object.has_meta("light"):
				var light = get_object_light(object)
				if light != null:
					light.energy = value
	
	#shadows
	if index == 20: #shadow enable
		if value == true:
			for object in selected:
				create_or_enable_shadow(object)
		else:
			for object in selected:
				disable_shadow(object)
	if index == 21: #shadow one sided
		for object in selected:
			if object.has_meta("shadow"):
				var shadow = get_object_shadow(object)
				if shadow != null:
					var flipped = tool_panel_object_menu.get_shadow_flipped()
					if value == false:
						shadow.occluder.cull_mode = OccluderPolygon2D.CULL_DISABLED
					elif value == true and flipped:
						shadow.occluder.cull_mode = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE
					else:
						shadow.occluder.cull_mode = OccluderPolygon2D.CULL_CLOCKWISE
				
	if index == 22: #shadow flip sides
		for object in selected:
			if object.has_meta("shadow"):
				var shadow = get_object_shadow(object)
				if shadow != null:
					var one_sided = tool_panel_object_menu.get_shadow_one_sided()
					if not one_sided:
						shadow.occluder.cull_mode = OccluderPolygon2D.CULL_DISABLED
					elif one_sided and value == true:
						shadow.occluder.cull_mode = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE
					else:
						shadow.occluder.cull_mode = OccluderPolygon2D.CULL_CLOCKWISE
				
func get_object_light(object):
	for child in object.get_children():
		if child is RemoteTransform2D and child.has_meta("light"):
			return child.get_node(child.get_remote_node())
	return null
	
func get_object_light_remote(object):
	for child in object.get_children():
		if child is RemoteTransform2D and child.has_meta("light"):
			return child
	return null

func create_or_enable_light(object):
	if object.has_meta("light"):
		var light = get_object_light(object)
		if light != null:
			light.visible = true
	else: #create light
		var light = PointLight2D.new()
		light.position = Vector2(tool_panel_object_menu.get_position_x(), tool_panel_object_menu.get_position_y())
		var texture = GradientTexture2D.new()
		texture.gradient = Gradient.new()
		texture.gradient.set_offset(0, 0.7)
		texture.gradient.set_offset(1, 0)
#		texture.gradient.add_point(0.7, Color.BLACK)
#		texture.gradient.add_point(0, Color.WHITE)
		texture.height = tool_panel_object_menu.get_light_resolution()
		texture.width = texture.height
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1, 0)
		texture.repeat = GradientTexture2D.REPEAT_NONE
		light.texture = texture
		#light.offset = Vector2(tool_panel_object_menu.get_light_offset_x(), tool_panel_object_menu.get_light_offset_y()) #changed to remote - offset does not change casting point
		light.texture_scale = tool_panel_object_menu.get_light_radius()/texture.get_height()*2
		light.color = tool_panel_object_menu.get_light_color()
		light.energy = tool_panel_object_menu.get_light_energy()
		light.range_z_max = 4095
		light.range_z_min = -4096
		light.range_layer_max = 0
		light.range_layer_min = -512
		light.shadow_enabled = true
		object.add_sibling(light)
		object.set_meta("light", true)
		var remote = RemoteTransform2D.new()
		remote.update_scale = false
		remote.position = Vector2(tool_panel_object_menu.get_light_offset_x(), tool_panel_object_menu.get_light_offset_y())
		remote.set_meta("light", true)
		object.add_child(remote)
		remote.set_remote_node(remote.get_path_to(light))
		
func disable_light(object):
	if object.has_meta("light"):
		var light = get_object_light(object)
		if light != null:
			light.visible = false
		
		
func get_object_shadow(object):
	for child in object.get_children():
		if child is LightOccluder2D:
			return child
	return null


func create_or_enable_shadow(object):
	if object.has_meta("shadow"):
		var shadow = get_object_shadow(object)
		if shadow != null:
			shadow.visible = true
	else: #create shadow
		var shadow = LightOccluder2D.new()
		shadow.occluder = OccluderPolygon2D.new()
		if object is CustomEllipse:
			print("custom ellipse detected")
			shadow.occluder.polygon = object.pointArray
		elif object is ColorRect:
			print("lines detected")
			var line = null
			for child in object.get_children():
				if child is Line2D:
					line = child
			if line == null:
				print("lines not found in children")
				return
			shadow.occluder.polygon = line.points
			shadow.position = -object.position
			shadow.occluder.closed = false
		elif "character" in object:
			print("token detected")
			shadow.occluder.polygon = object.ScaledPointArray
		else:
			print("square")
			var points = PackedVector2Array([Vector2(0,0), Vector2(object.size.x, 0), Vector2(object.size.x, object.size.y), Vector2(0, object.size.y)])
			shadow.occluder.polygon = points
		object.add_child(shadow)
		object.set_meta("shadow", true)
		
func disable_shadow(object):
	if object.has_meta("shadow"):
		var shadow = get_object_shadow(object)
		if shadow != null:
			shadow.visible = false
		
#value is new opacity, begin is in case of first call
func _on_fov_opacity_changed_signal(value):
	for token in Globals.new_map.tokens:
		if token.is_inside_tree():
			if not selected_tokens.has(token):
				token.fov.color.a = value
	
func select_token(token):
	selected = [token.token_polygon]
	select_objects()
	
func create_select_box(position):
	select_box = Panel.new()
	select_box.mouse_filter = Control.MOUSE_FILTER_PASS
	begin = position
	select_box.set_begin(begin)
	select_box.set_end(begin)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.5,0.5,1,0.2)
	style.border_color = Color.CORNSILK
	style.set_border_width_all(2)
	select_box.add_theme_stylebox_override("panel", style)
	select_box.material = unshaded_material
	select_box.connect("mouse_entered", _on_select_mouse_entered)
	select_box.connect("mouse_exited", _on_select_mouse_exited)
	$Select.add_child(select_box)

func create_targeting(targeting_data):
	print("targeting data: ", targeting_data)
	targeting = true
	
	if selected.size() > 0: #get macro start position
		targeting_origin = get_object_center(selected[0])
	
	# parse targeting_data
	if targeting_data[0].size() != 0: #has shape
		if targeting_data[0][0] == "circle": #circle shape
			var radius = targeting_data[0][1]
			targeting_shape = CustomCircle.new()
			targeting_shape.radius = radius
		elif targeting_data[0][0] == "rect": #rectangle shape
			var x = targeting_data[0][1]/2 #offsets from center
			var y = targeting_data[0][2]/2
			targeting_shape = Polygon2D.new()
			targeting_shape.polygon = [Vector2(x,y), Vector2(-x,y), Vector2(-x,-y), Vector2(x,-y)] #set polygon points
		elif targeting_data[0][0] == "cone": #cone shape
			var start_width = targeting_data[0][1]
			var end_width = targeting_data[0][2]
			var len = targeting_data[0][3]
			targeting_shape = Polygon2D.new()
			targeting_shape.polygon = [Vector2(0,-start_width/2), Vector2(len, -end_width/2), Vector2(len, end_width/2), Vector2(0, start_width/2)] #set polygon points
		elif targeting_data[0][0] == "cone_angle": #cone_angle shape
			var angle = targeting_data[0][1]
			var len = targeting_data[0][2]
			targeting_shape = CustomArc.new()
			targeting_shape.angle_size = angle
			targeting_shape.radius = len
			
		if targeting_shape != null: #was created
			if "mouse_filter" in targeting_shape: #rect does not have
				targeting_shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if targeting_origin != null:
				#set initial position
				if targeting_shape is CustomCircle:
					targeting_shape.center = targeting_origin
				else:
					targeting_shape.position = targeting_origin
			Globals.draw_comp.add_child(targeting_shape)
			
		#point
		if targeting_data[1][0] == "self": #position on selected
			if targeting_origin != null:
				if targeting_shape == null:
					var selected = get_clicked(targeting_origin)
					if "character" in selected:
						reset_targeting_variables()
						return [selected.character]
					reset_targeting_variables()
					return []
				else:
					targeting_self = true
			else:
				print("targeting self - nothing selected") #change to point
				targeting_self = true

		elif targeting_data[1][0] == "point": #position on selected
			if targeting_data[1].size() > 1:
				targeting_point_radius = targeting_data[1][1]
				if targeting_origin != null:
					targeting_range_circle = CustomCircle.new()
					targeting_range_circle.center = targeting_origin
					targeting_range_circle.radius = targeting_point_radius
					targeting_range_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
					Globals.draw_comp.add_child(targeting_range_circle)
				else: #no origin ignore range
					targeting_point_radius = -1
					
	return null
		

func update_targeting():
	if targeting_shape != null: #has shape set shape transforms
		if not targeting_self: # point - update position
			if targeting_point_radius != -1:
				if targeting_point_radius > targeting_origin.distance_to(mouse_pos):
					if targeting_shape is CustomCircle:
						targeting_shape.center = mouse_pos
					else:
						targeting_shape.position = mouse_pos
				else:
					return
			else: #unlimited range
				if targeting_shape is CustomCircle:
					targeting_shape.center = mouse_pos
				else:
					targeting_shape.position = mouse_pos
		#both self and point - set rotation based on mouse
		if targeting_origin != null:
			var angle = targeting_origin.angle_to_point(mouse_pos)
			targeting_shape.rotation = angle
			

func end_targeting():
	var selected_targets = []
	if targeting_shape == null: #point no shape - get clicked
		var selected_target = get_clicked(get_global_mouse_position())
		if "character" in selected_target:
			selected_targets.append(selected_target.character)
		emit_signal("targeting_end", selected_targets)
		reset_targeting_variables()
		return
	if targeting_origin == null: #set origin 
		targeting_origin = get_global_mouse_position()
		if targeting_self: #set initial position
			if targeting_shape is CustomCircle:
				targeting_shape.center = targeting_origin
			else:
				targeting_shape.position = targeting_origin
		return
	#has shape - get characters inside shape
	var rotated_polygon = [] #rotated polygon of shape object
	for point in targeting_shape.polygon:
		rotated_polygon.append(point.rotated(targeting_shape.rotation))
	
	var lines_children = Globals.draw_layer.get_children()
	for child in lines_children:
		if child.is_class("Node2D"): #inherits from Node2D
			if Globals.select_recursive:
				if child.get_class() == "Node2D": #is Node2D -> Layer
					lines_children.append_array(child.get_children())
			continue
		if "character" in child: #if character token
			child = child.get_child(0)
			var center = get_object_center(child) - targeting_shape.position
			if Geometry2D.is_point_in_polygon(center, rotated_polygon):
				selected_targets.append(child.character)
	#reset variables
	reset_targeting_variables()
	
	emit_signal("targeting_end", selected_targets)
	return
	
func reset_targeting_variables():
	targeting = false
	if targeting_shape != null:
		targeting_shape.queue_free()
	if targeting_range_circle != null:
		targeting_range_circle.queue_free()
	targeting_origin = null
	targeting_point_radius = -1
	targeting_self = false
	

func get_object_center(object):
	var distance = Vector2(0,0).distance_to((object.size * object.scale)/2)
	var angle = Vector2(0,0).angle_to_point((object.size * object.scale)/2) + object.rotation
	var center = object.position + Vector2(distance * cos(angle), distance * sin(angle))
	return center
