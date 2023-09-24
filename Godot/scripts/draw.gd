extends Node2D

@onready var lines = $Lines

#drawing
var pressed = false
var draw_enable = true
var current_panel: Panel #rect
var current_line: Line2D
var current_rect: ColorRect
var begin: Vector2
var min_max_x_y: Vector4 # min_x min_y max_x max_y

#select
var select_box: Panel #visual setection box
var selected = [] #list of selected items
var mouse_over_selected = false
var selected_creating = false
var selected_scaling = false
#hadles around selection - top bottom left right
var mouse_over_tl = false
var mouse_over_bl = false
var mouse_over_tr = false
var mouse_over_br = false

var select_size: Vector2
var select_pos: Vector2
var select_size_org: Vector2
var select_pos_org: Vector2
var selected_org_scales = []
var selected_org_pos = []
var flip_x = false
var flip_y = false

func _ready():
	get_viewport().files_dropped.connect(on_files_dropped) #drag and drop images

func _input(event):
	#button pressed
	if Input.is_action_just_pressed("mouseleft") and Globals.mouseOverButton:
		draw_enable = false
		return
	#pressed (not button)
	if Input.is_action_just_pressed("mouseleft"):
		draw_enable = true
	#line drawing finished
	if Input.is_action_just_released("mouseleft") and Globals.tool == "lines":
		if current_rect == null:
			return
		if min_max_x_y.x == min_max_x_y.z and min_max_x_y.y == min_max_x_y.w:
			lines.remove_child(current_rect)
			return
		#setting size of box around line for selection purposes
		current_rect.set_begin(Vector2(min_max_x_y.x, min_max_x_y.y))
		current_rect.set_end(Vector2(min_max_x_y.z, min_max_x_y.w))
		current_line.position = -current_rect.position
		current_rect = null
	#select box drawing | scaling finished
	if Input.is_action_just_released("mouseleft") and Globals.tool == "select":
		if mouse_over_selected and !selected_creating:
			return
		#scaling selection finished
		if selected_scaling:
			selected_scaling = false
			flip_x = false
			flip_y = false
			if mouse_over_tl:
				var mouse = get_global_mouse_position()
				current_panel = select_box.get_child(0)
				if mouse.x > current_panel.position.x and mouse.x < current_panel.position.x + current_panel.size.x:
					if mouse.y > current_panel.position.y and mouse.y < current_panel.position.y + current_panel.size.y:
						return
				mouse_over_tl = false
			if mouse_over_bl:
				var mouse = get_global_mouse_position()
				current_panel = select_box.get_child(1)
				if mouse.x > current_panel.position.x and mouse.x < current_panel.position.x + current_panel.size.x:
					if mouse.y > current_panel.position.y and mouse.y < current_panel.position.y + current_panel.size.y:
						return
				mouse_over_bl = false
			if mouse_over_tr:
				var mouse = get_global_mouse_position()
				current_panel = select_box.get_child(2)
				if mouse.x > current_panel.position.x and mouse.x < current_panel.position.x + current_panel.size.x:
					if mouse.y > current_panel.position.y and mouse.y < current_panel.position.y + current_panel.size.y:
						return
				mouse_over_tr = false
			if mouse_over_br:
				var mouse = get_global_mouse_position()
				current_panel = select_box.get_child(3)
				if mouse.x > current_panel.position.x and mouse.x < current_panel.position.x + current_panel.size.x:
					if mouse.y > current_panel.position.y and mouse.y < current_panel.position.y + current_panel.size.y:
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
		var lines_children = lines.get_children()
		#max select box size and position based on drawn size
		var max_x = select_box.position.x
		var max_y = select_box.position.y
		var min_x = select_box.size.x + select_box.position.x
		var min_y = select_box.size.y + select_box.position.y
		#snap selection size to children
		for child in lines_children:
#			if child.is_class("Panel"):
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
#			elif child.is_class("Line2D"):
#				if child.get_point_position(0).x >= select_box.position.x and child.get_point_position(0).y >= select_box.position.y:
#					if child.get_point_position(child.get_point_count()-1).x <= select_box.position.x + select_box.size.x:
#						if child.get_point_position(child.get_point_count()-1).y <= select_box.position.y + select_box.size.y:
#							selected.append(child)
#							#min
#							if child.get_point_position(0).x < min_x:
#								min_x = child.get_point_position(0).x
#							if child.get_point_position(child.get_point_count()-1).x < min_x:
#								min_x = child.get_point_position(child.get_point_count()-1).x
#							if child.get_point_position(0).y < min_y:
#								min_y = child.get_point_position(0).y
#							if child.get_point_position(child.get_point_count()-1).y < min_y:
#								min_y = child.get_point_position(child.get_point_count()-1).y
#							#max
#							if child.get_point_position(0).x > max_x:
#								max_x = child.get_point_position(0).x
#							if child.get_point_position(child.get_point_count()-1).x > max_x:
#								max_x = child.get_point_position(child.get_point_count()-1).x
#							if child.get_point_position(0).y > max_y:
#								max_y = child.get_point_position(0).y
#							if child.get_point_position(child.get_point_count()-1).y > max_y:
#								max_y = child.get_point_position(child.get_point_count()-1).y
		print(selected)
		if selected.is_empty():
			select_box.set_begin(Vector2(0,0))
			select_box.set_end(Vector2(0,0))
			return
		select_box.set_begin(Vector2(min_x, min_y))
		select_box.set_end(Vector2(max_x, max_y))
		#control points - handles
		create_handle(Control.PRESET_TOP_LEFT, 15)
		current_panel.connect("gui_input", _tl_handle_mouse_pressed)
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
		
		print(select_box.get_begin())
		print(select_box.get_end())
	#circle or rect drawing finished
	if Input.is_action_just_released("mouseleft") and (Globals.tool == "rect" or Globals.tool == "circle"):
		if current_panel == null:
			return
		if current_panel.size.x == 0 or current_panel.size.y == 0:
			lines.remove_child(current_panel)
	#else button held -> drawing
	if draw_enable:
		if Globals.tool == "rect":
			if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				pressed = event.pressed
				#just pressed - create objects
				if pressed:
					current_panel = Panel.new()
					begin = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
					current_panel.set_begin(begin)
					current_panel.set_end(begin)
					var style = StyleBoxFlat.new()
					style.bg_color = Globals.colorBack
					style.border_color = Globals.colorLines
					style.set_border_width_all(Globals.lineWidth)
					current_panel.add_theme_stylebox_override("panel", style)
					lines.add_child(current_panel)
					
			#moved - modify objects
			if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var end = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
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
					current_rect.color = Color(0,0,0,0)
					current_line = Line2D.new()
					current_line.default_color = Globals.colorLines
					current_line.width = Globals.lineWidth
					lines.add_child(current_rect)
					current_rect.add_child(current_line)
					var pos = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
					min_max_x_y = Vector4(pos.x, pos.y, pos.x, pos.y)
					current_line.add_point(pos)
			#moved - modify objects
			if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var pos = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
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
					current_panel = Panel.new()
					begin = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
					current_panel.set_begin(begin)
					current_panel.set_end(begin)
					var style = StyleBoxFlat.new()
					style.bg_color = Globals.colorBack
					style.border_color = Globals.colorLines
					style.set_border_width_all(Globals.lineWidth)
					style.corner_detail = 12
					current_panel.add_theme_stylebox_override("panel", style)
					lines.add_child(current_panel)
			#moved - modify objects
			if event is InputEventMouseMotion && pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var end = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
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
					current_panel.set_end(end)
				if current_panel.size.x < current_panel.size.y:
					current_panel.scale.x = current_panel.size.aspect()
					current_panel.size.x = current_panel.size.y
				else:
					current_panel.scale.y = 1/current_panel.size.aspect()
					current_panel.size.y = current_panel.size.x
				if Input.is_action_pressed("shift"):
					current_panel.scale.x = 1
					current_panel.scale.y = 1
				current_panel.get_theme_stylebox("panel", "").set_corner_radius_all(current_panel.size.x)
				
		if Globals.tool == "select":
			if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				pressed = event.pressed
				if mouse_over_selected: #drag
					return
				if mouse_over_tl or mouse_over_tr or mouse_over_bl or mouse_over_br: #scale
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
				#just pressed - create objects
				if pressed:
					#remove old select
					if $Select.get_child_count() != 0:
						$Select.remove_child($Select.get_child(0))
#					if $Select.get_child_count() != 0:
					select_box = Panel.new()
					begin = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
					select_box.set_begin(begin)
					var style = StyleBoxFlat.new()
					style.bg_color = Color(0.5,0.5,1,0.2)
					style.border_color = Color.CORNSILK
					style.set_border_width_all(2)
					select_box.add_theme_stylebox_override("panel", style)
					select_box.connect("gui_input", _on_select_pressed)
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
				#drag - move objects
				if mouse_over_selected and !selected_creating and !selected_scaling:
					var relative_offset = event.relative/get_node("../Camera2D").zoom
					for object in selected:
						object.position += relative_offset
					$Select.get_child(0).position += relative_offset
					return
				#scale objects
				elif selected_scaling:
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
				#drawing selection bow - update size
				else:
					var end = (event.position - Vector2(get_viewport().size/2))/get_node("../Camera2D").zoom + get_node("../Camera2D").position
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
						select_box.set_end(end)
					if Input.is_action_pressed("shift"):
						if select_box.size.x < select_box.size.y:
							select_box.size.x = select_box.size.y
						else:
							select_box.size.y = select_box.size.x
							
#debug
func _on_select_pressed(event: InputEvent):
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("selected: ", selected)
		
func _on_select_mouse_entered():
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
	current_panel.position = Vector2(-s/2,-s/2)
	current_panel.size = Vector2(s,s)
	current_panel.set_anchors_preset(preset)
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color.BLACK
	style.set_border_width_all(s/5)
	style.set_corner_radius_all(s)
	current_panel.add_theme_stylebox_override("panel", style)
	$Select.get_child(0).add_child(current_panel)
	
func _tl_handle_mouse_pressed():
	pass
	
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
		var begin = get_viewport().get_mouse_position()
		current_panel.set_begin(begin)
		current_panel.set_end(begin + Vector2(50,50))
		var style = StyleBoxTexture.new()
		style.texture = tex
		current_panel.add_theme_stylebox_override("panel", style)
		lines.add_child(current_panel)
		
		