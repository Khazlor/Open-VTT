#Author: Vladimír Horák
#Desc:
#List of Global variables - used for setting currrent map and campaign and easy data sharing between scripts

class_name Tool
extends Node

var campaign: Campaign_res
var map: Map_res
var new_map: Map_res

var draw_layer: Node2D
var drag_drop_canvas_layer: CanvasLayer #for dragging characters to map

var snapping = false
var measureTool = 1 #1 == line | 2 == circle | 3 == angle
var measureAngle = 30
var snappingFraction = 1
var tool = "rect"
var colorLines = Color(0,0,0,1)
var colorBack = Color(1,1,1,1)
var lineWidth = 10

var fontName = "default"
var font = load("res://fonts/Seagram tfb.ttf")
var fontColor = Color(0,0,0,1)
var fontSize = 10

var mouseOverButton = false
var mouseOverMaps = false
