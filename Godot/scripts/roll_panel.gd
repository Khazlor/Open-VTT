#Author: Vladimír Horák
#Desc:
#Script controlling roll panel functionality - parsing and evaluating roll commands

extends Control

const roll_panel_item_template = preload("res://componens/roll_panel_item.tscn")
var roll_panel_item: Control
#bools for determining roll parameters
var slash = false		#/
var roll = false 		#/r
var number_of_dice = 0	#/r Xdy - number of dice to be rolled
var sides_of_dice = 0	#/r xdY - what sided dice are to be rolled
var drop = false		#/r xdyDz - drop z dice (lowest)
var keep = false		#/r xdyKz - keep z dice (highest)
var highest = false		#/r xdydHz | xdykHz - drop|keep z highest dice
var lowest = false		#/r xdydLz | xdykLz - drop|keep z lowest dice
var keep_drop_dice = 0	#/r xdydZ | xdxkZ - number of dice to be kept / dropped
var expression = ""		#variable for composing parts of expression (x, y, z from above)
var final_expression_part = "" #variable for input of individual rolls before rolling (2d20)
var final_expression = "" #variable for final expression after rolls (2d20+5 -> 23+5)
var roll_hint = "" #string with individually rolled dice - for roll hint

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if $MarginContainer/VBoxContainer/TextEdit.has_focus():
		if Input.is_action_just_pressed("enter"):
			roll_panel_item = roll_panel_item_template.instantiate()
			$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(roll_panel_item)
			var text_in = $MarginContainer/VBoxContainer/TextEdit.text
			roll_panel_item.get_node("VBoxContainer/Text").text = "character rolls: " + text_in
			text_in += " " #placing ending char at end of input - to finish evaluating the preceding char
			for character in text_in: #reading char from input
				#determining whether /r was entered
				if !roll: #/r wasn't entered -> detecting /r
					if character == '/':
						slash = true
					elif slash and character == 'r': # /r
						slash = false
						roll = true
					else:
						if slash:
							slash = false
							roll_panel_item.get_node("VBoxContainer/Result").append_text('/')
						roll_panel_item.get_node("VBoxContainer/Result").append_text(character)
				else: #/r was entered -> evaluating roll expression
					if character == '/': #manual end of roll expression
						roll = false
						calculate_expression()
						final_expression = ""
						clear_dice()
						continue
					final_expression_part += character
					if character.is_valid_int(): #char is number
						expression += character
					elif character == 'd': #char is	'd' -> determining which d it is (xDyDz)
						if number_of_dice == 0: # xDy -> first d - preceding number is number of dice to be rolled
							if expression.length() == 0: # dy - number of dice was not entered -> 1 dice
								number_of_dice = 1
							else: # xdy - number of dice was entered
								if expression.is_valid_int():
									number_of_dice = expression.to_int()
									expression = ""
									print(number_of_dice)
								else:
									print("number of dice is not a number")
									final_expression += final_expression_part
									roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
									clear_dice()
									continue
						elif sides_of_dice == 0: # xdyDz -> second d - dropping dice - preceding number is sides of dice to be rolled
							if keep or drop: # already keeping or dropping dice
								print("invalid statement d")
								final_expression += final_expression_part
								roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
								clear_dice()
								continue
							if expression.length() == 0:
								print("sides of dice is not a number")
								final_expression += final_expression_part
								roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
								clear_dice()
								continue
							else:
								if expression.is_valid_int():
									sides_of_dice = expression.to_int()
									expression = ""
									drop = true
									print(sides_of_dice)
								else:
									print("sides of dice is not a number")
									final_expression += final_expression_part
									roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
									clear_dice()
									continue
						else: #xdydzD -> too many Ds
							print("invalid statement d")
							final_expression += final_expression_part
							roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
							clear_dice()
							continue
					elif character == 'k': #char is	'k'
						if number_of_dice > 0 and sides_of_dice == 0: #xdyKz -keeping dice -> xdy must be entered before - preceding number is sides of dice to be rolled
							if keep or drop: # already keeping or dropping dice
								print("invalid statement k")
								final_expression += final_expression_part
								roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
								clear_dice()
								continue
							if expression.is_valid_int():
								sides_of_dice = expression.to_int()
								expression = ""
								keep = true
								print(sides_of_dice)
							else:
								print("sides of dice is not a number")
								final_expression += final_expression_part
								roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
								clear_dice()
								continue
						else:
							print("invalid statement k") # xdy was not entered before k -> nothing to keep
							final_expression += final_expression_part
							roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
							clear_dice()
							continue
					elif character == 'h': #xdykHz | xdydHz - keep or drop highest dice
						if (keep or drop) and not(highest or lowest): #must be keeping or dropping dice & highest or lowest must not be entered
							highest = true
						else:
							print("invalid statement h")
							final_expression += final_expression_part
							roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
							clear_dice()
							continue
					elif character == 'l': #xdykLz | xdydLz - keep or drop lowest dice
						if (keep or drop) and not(highest or lowest): #must be keeping or dropping dice & highest or lowest must not be entered
							lowest = true
						else:
							print("invalid statement l")
							final_expression += final_expression_part
							roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
							clear_dice()
							continue
					else: #other char - roll dice
						if number_of_dice == 0: # only number was entered
							final_expression += final_expression_part
							roll_hint += final_expression_part
							clear_dice()
							continue
						if keep: #keeping dice - preceding number is number of dice to be kept
							keep_drop_dice = expression.to_int()
							print(keep_drop_dice)
							expression = ""
						elif drop: #dropping dice - preceding number is number of dice to be dropped
							keep_drop_dice = expression.to_int()
							print(keep_drop_dice)
							expression = ""
						else: #not keeping or dropping -> xdY - preceding number is sides of dice to be rolled
							if number_of_dice > 0 and sides_of_dice == 0:
								if expression.is_valid_int():
									sides_of_dice = expression.to_int()
									expression = ""
									print(sides_of_dice)
								else:
									print("sides of dice is not a number")
									final_expression += final_expression_part
									roll_panel_item.get_node("VBoxContainer/Result").append_text(final_expression_part)
									clear_dice()
									continue
						# rolling dice
						generate_dice()
						clear_dice()
						final_expression += character #adding last loaded char into final expression (unexpected character -> triggered rolling sequence)
						roll_hint += character
			if !final_expression.is_empty():
				calculate_expression()
				final_expression = ""
			roll = false
			slash = false
			print("done")
			#$MarginContainer/VBoxContainer/TextEdit.text = ""
			
# clear all variables of dice rolling
func clear_dice():
	drop = false
	keep = false
	highest = false
	lowest = false
	number_of_dice = 0
	sides_of_dice = 0
	keep_drop_dice = 0
	expression = ""
	final_expression_part = ""
	
# rolling dice
func generate_dice():
	var dice_array = []
	for number in number_of_dice:
		dice_array.append(randi_range(1, sides_of_dice))
		print("dice: ", number, " is ", dice_array[number])
	var dice_array_sorted = dice_array
	dice_array_sorted.sort()
	for number in number_of_dice:
		print("sortdice: ", number, " is ", dice_array_sorted[number])
	var dice_keep_drop_array = []
	if keep or drop:
		if keep:
			if lowest:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(number_of_dice-keep_drop_dice, number_of_dice)
			else:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(0, keep_drop_dice)
			for number in keep_drop_dice:
				dice_array.erase(dice_keep_drop_array[number])
				print("keepdice: ", number, " is ", dice_keep_drop_array[number])
		else: #drop
			if highest:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(number_of_dice-keep_drop_dice, number_of_dice)
			else:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(0, keep_drop_dice)
			for number in keep_drop_dice:
				dice_array.erase(dice_keep_drop_array[number])
				print("dropdice: ", number, " is ", dice_keep_drop_array[number])
					
	var sum = 0
	roll_hint += "("
	for item in dice_array:
		sum += item
		if item == 1:
			roll_hint += "[color=RED]" + str(item) + "[/color]+"
		elif item == sides_of_dice:
			roll_hint += "[color=GREEN]" + str(item) + "[/color]+"
		else: 
			roll_hint += str(item) + "+"
	final_expression += str(sum)
	print("sum: ", sum, "fe: ", final_expression)
	if keep or drop:
		for item in dice_keep_drop_array:
			roll_hint += "[color=#888888]" + str(item) + "[/color]+"
	roll_hint = roll_hint.left(-1) + ")"
		
# evaluating final expression
func calculate_expression():
	var calc_expression = Expression.new()
	print(final_expression + " <- calculating")
	var error = calc_expression.parse(final_expression)
	if error != OK:
		print("calculate error: " + calc_expression.get_error_text())
		return 
	var result = calc_expression.execute()
	if not calc_expression.has_execute_failed():
		roll_panel_item.get_node("VBoxContainer/Result").push_hint(roll_hint)
		roll_panel_item.get_node("VBoxContainer/Result").append_text(str(result))
		roll_panel_item.get_node("VBoxContainer/Result").pop()
	else:
		print("calculate error: " + calc_expression.get_error_text())
		roll_panel_item.get_node("VBoxContainer/Result").text = "expression error"
	roll_hint = ""
	

