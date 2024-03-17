#Author: Vladimír Horák
#Desc:
#List of Global variables - used for setting currrent map and campaign and easy data sharing between scripts

class_name Tool
extends Node

var enet_peer = null #for multiplayer
var spawner: MultiplayerSpawner = null

var campaign: Campaign_res
var map: Map_res
var new_map: Map_res

var draw_comp = Node2D
var draw_layer: Node2D
var drag_drop_canvas_layer: CanvasLayer #for dragging characters to map

var roll_panel: Control
var action_bar: FlowContainer
var turn_order: Window
var tool_bar
var windows: Control

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
