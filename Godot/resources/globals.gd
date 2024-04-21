#Author: Vladimír Horák
#Desc:
#List of Global variables - used for setting currrent map and campaign and easy data sharing between scripts

class_name Tool
extends Node

var base_dir_path # project folder for saving, res:// does not work in exported projects

var enet_peer = null #for multiplayer
var lobby: Node2D = null
var ip = ""
var port = 7000
var client = false

var campaign: Campaign_res
var map: Map_res
var new_map: Map_res

var draw_comp: Node2D
var draw_layer: Node2D
var drag_drop_canvas_layer: CanvasLayer #for dragging characters to map
var BG_ColorRect: ColorRect

var layers: Control
var roll_panel: Control
var action_bar: FlowContainer
var turn_order: Window
var tool_bar
var windows: Control
var char_tree: Tree

var snapping = false
var measureTool = 1 #1 == line | 2 == circle | 3 == angle
var measureAngle = 30
var snappingFraction = 1
var select_recursive = true
var tool = "select"
var colorLines = Color(0,0,0,1)
var colorBack = Color(1,1,1,1)
var lineWidth = 10

var fontName = "default"
var font = load("res://fonts/Seagram tfb.ttf")
var fontColor = Color(0,0,0,1)
var fontSize = 10

var mouseOverButton = false

var clipboard_objects = []
var clipboard_characters = []
var clipboard_lights = []

var tokenShapeDict = {"Square": PackedVector2Array([Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)]), "Pointed Square": PackedVector2Array([Vector2(0,0), Vector2(1,0), Vector2(1,0.8), Vector2(0.5,1), Vector2(0,0.8)])}


func load_texture(file_path):
	if not FileAccess.file_exists(file_path):
		print("load texture - file does not exist")
		return null
	var image = Image.load_from_file(file_path)
	var texture = ImageTexture.create_from_image(image)
	return texture

func on_server_disconnected(): #handles closing of server on client side
	print("server connetion lost: ", multiplayer.multiplayer_peer.get_connection_status())
	var i = 0
	await get_tree().create_timer(0.05).timeout
	while i < 5:
		print("connection lost ", i, multiplayer.multiplayer_peer.get_connection_status())
		var err = Globals.enet_peer.create_client(Globals.ip, Globals.port)
		print("reconnect err: ", err)
		if err == 0:
			await get_tree().create_timer(0.05).timeout
			multiplayer.multiplayer_peer.poll()
			var poll_attemp = 0
			while multiplayer.multiplayer_peer.get_connection_status() == 1 and poll_attemp < 5:
				poll_attemp += 1
				print("connecting")
				await get_tree().create_timer(0.1).timeout
				multiplayer.multiplayer_peer.poll()
			print("connection lost - try reconnect", i, multiplayer.multiplayer_peer.get_connection_status())
		multiplayer.multiplayer_peer.poll()
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print("reconnected")
			return
		i += 0.5
		await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
