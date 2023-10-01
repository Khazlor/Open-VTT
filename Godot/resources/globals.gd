class_name Tool
extends Node

var snapping = false
var measureTool = 1 #1 == line | 2 == circle | 3 == angle
var measureAngle = 30
var snappingFraction = 1
var tool = "rect"
var colorLines = Color(0,0,0,1)
var colorBack = Color(1,1,1,1)
var lineWidth = 10

var mouseOverButton = false
