extends Node2D

var char_sheet = preload("res://UI/character_sheet.tscn")

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
var mouse_over_selected = false
var selected_creating = false
var selected_scaling = false
var selected_rotating = false
#hadles around selection - top bottom left right
var mouse_over_tl = false
var mouse_over_bl = false
var mouse_over_tr = false
var mouse_over_br = false
var mouse_over_rotate = false

var select_size: Vector2
var select_pos: Vector2
var select_center_pos: Vector2
var select_size_org: Vector2
var select_pos_org: Vector2
var select_rot_org: float
var selected_org_scales = []
var selected_org_pos = []
var selected_org_rots = []
var flip_x = false
var flip_y = false

var mouse_pos = Vector2(0,0)

var last_event_pos = Vector2(-1,-1)

@export var layers_root: Node2D = null

func _ready():
	get_viewport().files_dropped.connect(on_files_dropped) #drag and drop images

func _unhandled_input(event):
#	print_tree_pretty() #DEBUG TODO remove
	if event is InputEventMouse:
		if Globals.draw_layer == null: #check if layer is selected
			return
		var mouse_pos = get_global_mouse_position()
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

			print(mouse_pos)
			mouse_pos = round(mouse_pos/(70/Globals.snappingFraction))*(70/Globals.snappingFraction) #snap to grid
			print(mouse_pos)
		#skip if position not changed
	#	if last_event_pos == event.position:
	#		return
	#	else:
	#		last_event_pos = event.position

		#button pressed or mouse moved
		if Input.is_action_just_pressed("mouseleft") and Globals.mouseOverButton:
			draw_enable = false
			return
		#pressed (not button)
		if Input.is_action_just_pressed("mouseleft"):
			print("mouse pressed")
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
			if mouse_over_selected and !selected_creating and !selected_scaling:
				return
			#rotating selection finished
			if selected_rotating:
				selected_rotating = false
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
					mouse_over_tl = false
				if mouse_over_bl:
					current_panel = select_box.get_child(1)
					if mouse_pos.x > current_panel.position.x and mouse_pos.x < current_panel.position.x + current_panel.size.x:
						if mouse_pos.y > current_panel.position.y and mouse_pos.y < current_panel.position.y + current_panel.size.y:
							return
					mouse_over_bl = false
				if mouse_over_tr:
					current_panel = select_box.get_child(2)
					if mouse_pos.x > current_panel.position.x and mouse_pos.x < current_panel.position.x + current_panel.size.x:
						if mouse_pos.y > current_panel.position.y and mouse_pos.y < current_panel.position.y + current_panel.size.y:
							return
					mouse_over_tr = false
				if mouse_over_br:
					current_panel = select_box.get_child(3)
					if mouse_pos.x > current_panel.position.x and mouse_pos.x < current_panel.position.x + current_panel.size.x:
						if mouse_pos.y > current_panel.position.y and mouse_pos.y < current_panel.position.y + current_panel.size.y:
							return
					mouse_over_br = false
				return
			if !selected_creating:
				return
			#selection box finished drawing
			selected_creating = false
			selected.clear()
			if $Select.get_child_count() == 0:
				return
			var lines_children = Globals.draw_layer.get_children()
			#max select box size and position based on drawn size
			var max_x = select_box.position.x
			var max_y = select_box.position.y
			var min_x = select_box.size.x + select_box.position.x
			var min_y = select_box.size.y + select_box.position.y
			#snap selection size to children
			for child in lines_children:
				if child.is_class("Node2D"):
					continue
				if child.rotation == 0:
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
					var max = Vector2()#max x,y of rotated polygon
					var min = Vector2()#min x,y of rotated polygon
					max.x = top_left.x
					max.x = top_left.y
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
					if min.x >= select_box.position.x and min.y >= select_box.position.y:
						if max.x <= select_box.position.x + select_box.size.x:
							if max.y <= select_box.position.y + select_box.size.y:
								selected.append(child)
								if max.x > max_x:
									max_x = max.x
								if max.y > max_y:
									max_y = max.y
								if min.x < min_x:
									min_x = min.x
								if min.y < min_y:
									min_y = min.y
			print(selected)
			#if nothing in dragged square -> get clicked
			if selected.is_empty():
				for x in range(lines_children.size()):
					var child = lines_children[-x-1]
					if child.is_class("Node2D"):
						continue
					print("mouse pos: ", mouse_pos)
					print("pos: ", child.position)
					print("size: ", child.size)
					print("scale: ", child.scale)
					if child.rotation == 0:
						if child.position.x <= mouse_pos.x and child.position.y <= mouse_pos.y:
							if child.position.x + child.size.x*child.scale.x >= mouse_pos.x:
								if child.position.y + child.size.y*child.scale.y >= mouse_pos.y:
									selected.append(child)
									break
					else: #calculate with rotation
						var diagonal = Vector2(0,0).distance_to(child.size * child.scale)
						var angle = Vector2(0,0).angle_to_point(child.size * child.scale)
						var top_left = child.position
						var top_right = Vector2(child.position.x + child.size.x * child.scale.x * cos(child.rotation), child.position.y + child.size.x * child.scale.x * sin(child.rotation))
						var bottom_right = Vector2(child.position.x + diagonal * cos(angle + child.rotation), child.position.y + diagonal * sin(angle + child.rotation))
						var bottom_left = Vector2(child.position.x + child.size.y * child.scale.y * cos(deg_to_rad(90) + child.rotation), child.position.y + child.size.y * child.scale.y * sin(deg_to_rad(90) + child.rotation))
						if Geometry2D.is_point_in_polygon(mouse_pos, PackedVector2Array([top_left, top_right, bottom_right, bottom_left])):
							selected.append(child)
							break
				if selected.is_empty():
					select_box.set_begin(Vector2(0,0))
					select_box.set_end(Vector2(0,0))
					return
			
			
			#if only single item selected - affect select box by item rotation
			if selected.size() == 1:
				print("one item")
				var s = selected[0]
				select_box.rotation = s.rotation
				select_box.pivot_offset = s.pivot_offset
				select_box.position = s.position
				select_box.size = s.size*s.scale
			else:
				select_box.set_begin(Vector2(min_x, min_y))
				select_box.set_end(Vector2(max_x, max_y))
				select_box.rotation = 0
				select_box.pivot_offset = Vector2(min_x + select_box.size.x/2, min_y + select_box.size.y/2)
			print(selected)
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
			
			for child in select_box.get_children():
				print(child.get_signal_connection_list("mouse_entered"))
			print(select_box.get_begin())
			print(select_box.get_end())
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
							current_label.mouse_filter = Control.MOUSE_FILTER_PASS
							current_line.add_child(current_rect)
							current_rect.set_owner(layers_root)
							current_rect.add_child(current_label)
							current_label.set_owner(layers_root)
							current_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
					#moved - modify objects
					if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						current_line.set_point_position(1, mouse_pos)
						current_label.text = str(snapped(current_line.get_point_position(0).distance_to(current_line.get_point_position(1))/14, 0.01)) + " ft"
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
							current_label.mouse_filter = Control.MOUSE_FILTER_PASS
							Globals.draw_layer.add_child(current_rect)
							current_rect.set_owner(layers_root)
							current_measure.append(current_rect)
							current_rect.add_child(current_label)
							current_label.set_owner(layers_root)
					#moved - modify objects
					if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						current_circle.radius = begin.distance_to(mouse_pos)
						current_label.text = str(snapped(begin.distance_to(mouse_pos)/14, 0.01)) + " ft"
						current_rect.set_position(mouse_pos)
						current_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
						print(current_circle.center, begin)
						print(current_circle.radius, current_circle.size, current_circle.position, mouse_pos)
						
				if Globals.measureTool == 3: #measure angle
					if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						pressed = event.pressed
						#just pressed - create objects
						if pressed:
							begin = mouse_pos
							current_arc = CustomArc.new()
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
						current_label.text = str(snapped(begin.distance_to(mouse_pos)/14, 0.01)) + " ft"
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
						selected_scaling = true
						min_max_x_y = Vector4(select_box.position.x, select_box.position.y, select_box.position.x+select_box.size.x, select_box.position.y+select_box.size.y)
						select_pos_org = select_box.position
						select_size_org = select_box.size
						selected_org_scales.clear()
						selected_org_pos.clear()
						for object in selected:
							selected_org_scales.append(object.scale)
							selected_org_pos.append(object.position)
						return
					if mouse_over_rotate: #rotate
						print("mouse_over_rotate")
						selected_rotating = true
						select_center_pos = select_box.position + select_box.size/2
						select_pos_org = select_box.position
						select_rot_org = select_box.rotation
						selected_org_rots.clear()
						selected_org_pos.clear()
						for object in selected:
							print(object.position)
							selected_org_rots.append(object.rotation)
							selected_org_pos.append(object.position)
						return
					if mouse_over_selected: #drag
						print("mouse_over_selected")
						return
					#just pressed - create objects
					if pressed:
						#remove old select
						print("selection creating")
						for child in $Select.get_children():
							child.queue_free()
							#$Select.remove_child($Select.get_child(0))
	#					if $Select.get_child_count() != 0:
						select_box = Panel.new()
						select_box.mouse_filter = Control.MOUSE_FILTER_PASS
						begin = mouse_pos
						select_box.set_begin(begin)
						select_box.set_end(begin)
						var style = StyleBoxFlat.new()
						style.bg_color = Color(0.5,0.5,1,0.2)
						style.border_color = Color.CORNSILK
						style.set_border_width_all(2)
						select_box.add_theme_stylebox_override("panel", style)
						select_box.connect("mouse_entered", _on_select_mouse_entered)
						select_box.connect("mouse_exited", _on_select_mouse_exited)
						$Select.add_child(select_box)
	#					else:
	#						selected.clear()
	#						current_panel = $Select.get_child(0)
	#						begin = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
	#						current_panel.set_begin(begin)
	#						current_panel.set_end(begin)
						selected_creating = true
				#moved - modify objects
				if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					print("selection drag - scaling: " + str(selected_scaling))
					if mouse_over_bl: print("bl")
					if mouse_over_tl: print("tl")
					if mouse_over_br: print("br")
					if mouse_over_tr: print("tr")
					if mouse_over_rotate: print("rotate")
					if $Select.get_child_count() == 0:
						return
					#drag - move objects
					if mouse_over_selected and !selected_creating and !selected_scaling and !selected_rotating:
						print("drag")
						var relative_offset = event.relative/get_node("../Camera2D").zoom
						for object in selected:
							object.position += relative_offset
						$Select.get_child(0).position += relative_offset
						return
					#rotate objects
					elif selected_rotating:
						print("rotate")
						var angle = select_center_pos.angle_to_point(get_global_mouse_position()) + deg_to_rad(90)
						select_box.pivot_offset = select_box.size/2
						select_box.rotation = angle
						var i = 0
						for object in selected:
							print(rad_to_deg(angle), angle)
							var distance = select_center_pos.distance_to(object.position)
							var angle_org = select_center_pos.angle_to_point(selected_org_pos[i])
							object.position = Vector2(select_center_pos.x + cos(angle_org + angle) * distance, select_center_pos.y + sin(angle_org + angle) * distance)
							object.rotation = selected_org_rots[i] + angle
							i += 1
					#scale objects
					elif selected_scaling:
						print("scale")
						select_pos = select_box.position
						select_size = select_box.size
						var relative_offset = event.relative/get_node("../Camera2D").zoom
						if mouse_over_tl: #scale
							if select_box.size.x-relative_offset.x > 0 and select_box.size.y-relative_offset.y > 0: #tl
								var scal = (select_box.size-relative_offset)/select_box.size
								select_box.set_begin(Vector2((select_box.get_begin().x+relative_offset.x), (select_box.get_begin().y+relative_offset.y)))
								var i = 0
								for object in selected:
									object.scale = (select_size/select_size_org) * selected_org_scales[i]
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
									i += 1
							elif select_box.size.x-relative_offset.x > 0: #bl
								flip_y = !flip_y
								mouse_over_bl = true
								mouse_over_tl = false
							elif select_box.size.y-relative_offset.y > 0: #tr
								flip_x = !flip_x
								mouse_over_tr = true
								mouse_over_tl = false
							else: #br
								flip_x = !flip_x
								flip_y = !flip_y
								mouse_over_tl = true
								mouse_over_tl = false
						elif mouse_over_bl: #scale
							if select_box.size.x-relative_offset.x > 0 and select_box.size.y+relative_offset.y > 0: #bl
								var scal = Vector2((select_box.size.x-relative_offset.x)/select_box.size.x, (select_box.size.y+relative_offset.y)/select_box.size.y)
								select_box.set_begin(Vector2((select_box.get_begin().x+relative_offset.x), select_pos.y))
								select_box.size.y += relative_offset.y
								var i = 0
								for object in selected:
									object.scale = (select_size/select_size_org) * selected_org_scales[i]
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
									i += 1
							elif select_box.size.x-relative_offset.x > 0: #tl
								flip_y = !flip_y
								mouse_over_tl = true
								mouse_over_bl = false
							elif select_box.size.y+relative_offset.y > 0: #br
								flip_x = !flip_x
								mouse_over_br = true
								mouse_over_bl = false
							else: #tr
								flip_x = !flip_x
								flip_y = !flip_y
								mouse_over_tr = true
								mouse_over_bl = false
						elif mouse_over_tr: #scale
							if select_box.size.x+relative_offset.x > 0 and select_box.size.y-relative_offset.y > 0: #tr
								var scal = Vector2((select_box.size.x+relative_offset.x)/select_box.size.x, (select_box.size.y-relative_offset.y)/select_box.size.y)
								select_box.size.x += relative_offset.x
								select_box.set_begin(Vector2(select_pos.x, select_box.get_begin().y+relative_offset.y))
								var i = 0
								for object in selected:
									object.scale = (select_size/select_size_org) * selected_org_scales[i]
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
									i += 1
							elif select_box.size.x+relative_offset.x > 0: #br
								flip_y = !flip_y
								mouse_over_br = true
								mouse_over_tr = false
							elif select_box.size.y-relative_offset.y > 0: #tl
								flip_x = !flip_x
								mouse_over_tl = true
								mouse_over_tr = false
							else: #bl
								flip_x = !flip_x
								flip_y = !flip_y
								mouse_over_bl = true
								mouse_over_tr = false
						elif mouse_over_br: #scale
							if select_box.size.x+relative_offset.x > 0 and select_box.size.y+relative_offset.y > 0: #br
								var scal = (select_box.size+relative_offset)/select_box.size
								select_box.size += relative_offset
								var i = 0
								for object in selected:
									object.scale = (select_size/select_size_org) * selected_org_scales[i]
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
									i += 1
							elif select_box.size.x+relative_offset.x > 0: #tr
								flip_y = !flip_y
								mouse_over_tr = true
								mouse_over_br = false
							elif select_box.size.y+relative_offset.y > 0: #bl
								flip_x = !flip_x
								mouse_over_bl = true
								mouse_over_br = false
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
		if Input.is_action_just_pressed("Delete"):
			for child in selected:
				child.queue_free()
			#remove select box
			for child in $Select.get_children():
				child.queue_free()
				
			#resetting select box state variables
			mouse_over_selected = false
			selected_creating = false
			selected_scaling = false
			selected_rotating = false
			mouse_over_tl = false
			mouse_over_bl = false
			mouse_over_tr = false
			mouse_over_br = false
		elif Input.is_action_just_pressed("Escape"):
			get_tree().change_scene_to_file("res://scenes/Maps.tscn")
		elif Input.is_action_just_pressed("I-pressed"):
			var ch_sh = char_sheet.instantiate()
			ch_sh.position = get_viewport().get_mouse_position()
			add_child(ch_sh)
		
func _on_select_mouse_entered():
	print("mouse over selected")
	mouse_over_selected = true
	
func _on_select_mouse_exited():
	mouse_over_selected = false
	
#func create_handle(x: float, y: float, s: float):
#	current_panel = Panel.new()
#	current_panel.position = Vector2(x-s/2,y-s/2)
#	current_panel.size = Vector2(s,s)
#	var style = StyleBoxFlat.new()
#	style.bg_color = Color.WHITE
#	style.border_color = Color.BLACK
#	style.set_border_width_all(s/5)
#	style.set_corner_radius_all(s)
#	current_panel.add_theme_stylebox_override("panel", style)
#	$Select.get_child(0).add_child(current_panel)

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
	$Select.get_child(0).add_child(current_panel)
	
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
	
