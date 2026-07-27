#Author: Vladimír Horák
#Desc:
#Script for controlling camera in map scene

extends Camera2D

#finger tracking for gestures
var touches: Array = []
var org_zoom: Vector2 = Vector2(0,0)
var org_distance: float = 0.0
var org_mid_point_pos: Vector2 = Vector2(0,0)
var mid_point_pos: Vector2 = Vector2(0,0)
var org_camera_pos: Vector2 = Vector2(0,0)
#var panning = false
#var zooming = false

#settings for map camera navigation
var zoomSpd: float = 0.05
var minZoom: float = 0.001
var maxZoom: float = 2.0
var dragSen: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.camera = self
	
func update_midpoint():
	if touches.size() >= 2:
		mid_point_pos = (touches[0][1]+touches[1][1])/2

#handles user input
func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			print(event.index)
			if touches.size() == 0:
				touches.append([event.index, event.position])
			elif touches.size() == 1:
				touches.append([event.index, event.position])
				org_mid_point_pos = (touches[0][1]+touches[1][1])/2
				org_distance = touches[0][1].distance_to(touches[1][1])
				org_camera_pos = position
				org_zoom = zoom
				Globals.draw_comp.abort_all_inputs()
		else:
			if touches.size() < 2 or ([0][0] == event.index or touches[1][0] == event.index):
				touches.clear()
				Globals.draw_comp.resume_all_inputs()
		return
			#panning = false
			#zooming = false
	elif event is InputEventScreenDrag:
		if touches.size() == 2:
			if touches[0][0] == event.index:
				touches[0][1] = event.position
			elif touches[1][0] == event.index:
				touches[1][1] = event.position
			else:
				return
			update_midpoint()
			#camera pan
			position = org_camera_pos + ((org_mid_point_pos - mid_point_pos) * dragSen / zoom)
			
			#camera zoom
			var distance_change = touches[0][1].distance_to(touches[1][1]) / org_distance
			zoom = org_zoom * distance_change
	#movement
	if event is InputEventMouseMotion and Input.is_action_pressed("mousemiddle"):
		position -= event.relative * dragSen / zoom
	#zoom
	elif event is InputEventMouseButton or event is InputEventMagnifyGesture:
		if event is InputEventMagnifyGesture:
			print("mag gesture")
			zoom *= event.factor
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoomSpd, zoomSpd)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoomSpd, zoomSpd)
		else:
			return
		zoom = clamp(zoom, Vector2(minZoom, minZoom), Vector2(maxZoom, maxZoom))
		#resize selection box handles
		if $"../Draw/Select".get_child_count() == 1:
			var handles = $"../Draw/Select".get_child(0).get_children()
			for handle in handles:
				handle.scale = Vector2(1/zoom.x,1/zoom.y)
