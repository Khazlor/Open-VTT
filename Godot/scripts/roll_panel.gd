#Author: Vladimír Horák
#Desc:
#Script controlling roll panel functionality - parsing and evaluating roll commands

extends Control

const roll_panel_item_template = preload("res://components/roll_panel_item.tscn")
var roll_panel_item: Control
#bools for determining roll parameters
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
var result_node

var results = []
var roll_hints = []

var assignment_regex
var attr_regex
var value_regex

var query_or_cond_regex

#new regexes
var assign_start_regex
var inner_regex

@onready var scroll_bar = $MarginContainer/VBoxContainer/ScrollContainer.get_v_scroll_bar()
@onready var textEdit = $MarginContainer/VBoxContainer/TextEdit
@onready var query_diag = $QueryDialog
@onready var query_diag_opt = $QueryDialog/VBoxContainer/OptionButton
@onready var query_diag_te = $QueryDialog/VBoxContainer/TextEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.roll_panel = self
	
	assignment_regex = RegEx.new()
	assignment_regex.compile("[\\$@]\\S+\\s*=\\s*\\[.*]") # regex to detect $attr = [attr value] or @attr = [attr value]
	attr_regex = RegEx.new()
	attr_regex.compile("(?<=[\\$@])\\S+") # regex to get attr
	value_regex = RegEx.new()
	value_regex.compile("(?<=\\[).*(?=])") # regex to get attr value - all between []
	
	query_or_cond_regex = RegEx.new()
	query_or_cond_regex.compile("(?<=\\?{).*(?=})") # regex to get query or condition data - all between {} in ?{query or condition}
	
	#new
	assign_start_regex = RegEx.new()
	assign_start_regex.compile("^\\s*=\\s*\\[") # regex to see if = [ is at start of string after attribute - start of assignment
	
	inner_regex = RegEx.new()
	inner_regex.compile("(\\/r|@|\\$|\\?{)") # regex to see if inner resolve is needed
	
	scroll_bar.connect("changed", on_scroll_bar_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
#handles scroll to bottom on expand
func on_scroll_bar_changed():
	scroll_bar.value = scroll_bar.max_value


func _on_text_edit_gui_input(event):
	if Input.is_action_just_pressed("enter"):
		if Input.is_action_pressed("shift"):
			textEdit.insert_text_at_caret("\n") #insert linebreak - one will be deleted by signal
			return
		textEdit.connect("text_changed", remove_break) #deletes linebreak added by submitting - will occur after this function
		#execute command
		await execute_macro(textEdit.text)
	
		
func create_roll_panel():
	roll_panel_item = roll_panel_item_template.instantiate()
	result_node = roll_panel_item.get_node("VBoxContainer/Result")
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(roll_panel_item)


func evaluate_roll(roll_section: String):
	#print("roll: ", roll_section)
	roll_section += " "#adding char to end of expression - to trigger roll if untriggered at end
	for character in roll_section:
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
						#print(number_of_dice)
					else:
						print("number of dice is not a number")
						final_expression += final_expression_part
						result_node.append_text(final_expression_part)
						clear_dice()
						continue
			elif sides_of_dice == 0: # xdyDz -> second d - dropping dice - preceding number is sides of dice to be rolled
				if keep or drop: # already keeping or dropping dice
					print("invalid statement d")
					final_expression += final_expression_part
					result_node.append_text(final_expression_part)
					clear_dice()
					continue
				if expression.length() == 0:
					print("sides of dice is not a number")
					final_expression += final_expression_part
					result_node.append_text(final_expression_part)
					clear_dice()
					continue
				else:
					if expression.is_valid_int():
						sides_of_dice = expression.to_int()
						expression = ""
						drop = true
						#print(sides_of_dice)
					else:
						print("sides of dice is not a number")
						final_expression += final_expression_part
						result_node.append_text(final_expression_part)
						clear_dice()
						continue
			else: #xdydzD -> too many Ds
				print("invalid statement d")
				final_expression += final_expression_part
				result_node.append_text(final_expression_part)
				clear_dice()
				continue
		elif character == 'k': #char is	'k'
			if number_of_dice > 0 and sides_of_dice == 0: #xdyKz -keeping dice -> xdy must be entered before - preceding number is sides of dice to be rolled
				if keep or drop: # already keeping or dropping dice
					print("invalid statement k")
					final_expression += final_expression_part
					result_node.append_text(final_expression_part)
					clear_dice()
					continue
				if expression.is_valid_int():
					sides_of_dice = expression.to_int()
					expression = ""
					keep = true
					#print(sides_of_dice)
				else:
					print("sides of dice is not a number")
					final_expression += final_expression_part
					result_node.append_text(final_expression_part)
					clear_dice()
					continue
			else:
				print("invalid statement k") # xdy was not entered before k -> nothing to keep
				final_expression += final_expression_part
				result_node.append_text(final_expression_part)
				clear_dice()
				continue
		elif character == 'h': #xdykHz | xdydHz - keep or drop highest dice
			if (keep or drop) and not(highest or lowest): #must be keeping or dropping dice & highest or lowest must not be entered
				highest = true
			else:
				print("invalid statement h")
				final_expression += final_expression_part
				result_node.append_text(final_expression_part)
				clear_dice()
				continue
		elif character == 'l': #xdykLz | xdydLz - keep or drop lowest dice
			if (keep or drop) and not(highest or lowest): #must be keeping or dropping dice & highest or lowest must not be entered
				lowest = true
			else:
				print("invalid statement l")
				final_expression += final_expression_part
				result_node.append_text(final_expression_part)
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
				#print(keep_drop_dice)
				expression = ""
			elif drop: #dropping dice - preceding number is number of dice to be dropped
				keep_drop_dice = expression.to_int()
				#print(keep_drop_dice)
				expression = ""
			else: #not keeping or dropping -> xdY - preceding number is sides of dice to be rolled
				if number_of_dice > 0 and sides_of_dice == 0:
					if expression.is_valid_int():
						sides_of_dice = expression.to_int()
						expression = ""
						#print(sides_of_dice)
					else:
						print("sides of dice is not a number")
						final_expression += final_expression_part
						result_node.append_text(final_expression_part)
						clear_dice()
						continue
			# rolling dice
			generate_dice()
			clear_dice()
			final_expression += character #adding last loaded char into final expression (unexpected character -> triggered rolling sequence)
			roll_hint += character
	print("fe = ", final_expression)
	if !final_expression.is_empty():
		var res = calculate_expression()
		final_expression = ""
		return res
	print("done")
	return ""

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
		#print("dice: ", number, " is ", dice_array[number])
	var dice_array_sorted = dice_array.duplicate()
	dice_array_sorted.sort()
	#for number in number_of_dice:
		#print("sortdice: ", number, " is ", dice_array_sorted[number])
	var dice_keep_drop_array = []
	if keep or drop:
		if keep:
			if lowest:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(number_of_dice-keep_drop_dice, number_of_dice)
			else:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(0, keep_drop_dice)
		else: #drop
			if highest:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(number_of_dice-keep_drop_dice, number_of_dice)
			else:
				for number in keep_drop_dice:
					dice_keep_drop_array = dice_array_sorted.slice(0, keep_drop_dice)
					
	var sum = 0
	roll_hint += "("
	for item in dice_array:
		if item in dice_keep_drop_array:
			roll_hint += "[color=#666666]" + str(item) + "[/color]+"
			dice_keep_drop_array.erase(item)
			continue
		sum += item
		if item == 1:
			roll_hint += "[color=RED]" + str(item) + "[/color]+"
		elif item == sides_of_dice:
			roll_hint += "[color=GREEN]" + str(item) + "[/color]+"
		else: 
			roll_hint += str(item) + "+"
	final_expression += str(sum)
	#print("sum: ", sum, "fe: ", final_expression)
	roll_hint = roll_hint.left(-1) + ")"
		
# evaluating final expression
func calculate_expression():
	var calc_expression = Expression.new()
	print(final_expression + " <- calculating")
	var error = calc_expression.parse(final_expression)
	if error != OK:
		result_node.append_text("<expression error>")
		print("calculate error: " + calc_expression.get_error_text())
		return "<expression error>"
	var result = calc_expression.execute()
	if not calc_expression.has_execute_failed():
		results.append(str(result))
		result = "\u001A_" + str(roll_hints.size()) + "_" + str(result)
		roll_hints.append(roll_hint)
#		result_node.push_hint(roll_hint)
#		result_node.append_text(str(result))
#		result_node.pop()
	else:
		print("calculate error: " + calc_expression.get_error_text())
		result_node.append_text("<expression error>")
		result = "<expression error>"
	roll_hint = ""
	return str(result)
	
#removes break created by enter (submit)
func remove_break():
	textEdit.backspace()
	textEdit.disconnect("text_changed", remove_break)
	
#executes macro by character to all targets
# basic syntax:
# $hp = token.hp
# @hp = target.hp
func execute_macro(text_in: String, character: Character = null, targets = []):
	var split_text = split_command(text_in)
	if split_text.size() > 1: #has targeting
		var targeting_data = targeting(split_text[1])
		if targeting_data != null:
			targets = Globals.draw_comp.create_targeting(targeting_data)
			if targets == null: #nothing selected yet - wait for selection
				targets = await Globals.draw_comp.targeting_end
			print("targets targeted: ", targets)
	if targets.is_empty(): #roll once
		await execute_roll(split_text[0], character, null)
	else: #roll for each target - TODO probably do not create roll panel for each
		for target in targets:
			await execute_roll(split_text[0], character, target)
					
					
func execute_roll(text_in: String, character: Character = null, target: Character = null):
	print("target = ", target)
	
	create_roll_panel()
	var text_in_arr = [text_in + "  "] #array passed by reference
	await resolve_inner(text_in_arr, 0, "", character, target)
	append_text(text_in_arr)

#replace all found attributes
func replace_attributes(text_in: String, character: Character, target: Character):
	if character != null:
		var i = text_in.find("$")
		while i != -1:
			var len = text_in.find(" ", i)
			var attr
			if len == -1: #to the end of string
				attr = text_in.substr(i + 1, -1)
				print("attr: ", attr)
				if character.attributes.has(attr):
					text_in = text_in.erase(i, attr.length() + 1)
					text_in += character.attributes[attr][1]
				break
			else:
				attr = text_in.substr(i + 1, len - (i + 1))
			if character.attributes.has(attr):
				text_in = text_in.erase(i, attr.length() + 1)
				text_in.insert(i, character.attributes[attr][1])
				i = text_in.find("$", i)
			else:
				i = text_in.find("$", i + 1)
	if target != null:
		var i = text_in.find("@")
		while i != -1:
			var len = text_in.find(" ", i)
			var attr
			if len == -1: #to the end of string
				attr = text_in.substr(i + 1, -1)
				if target.attributes.has(attr):
					text_in = text_in.erase(i, attr.length() + 1)
					text_in += target.attributes[attr]
				break
			else:
				attr = text_in.substr(i + 1, len - (i + 1))
			if target.attributes.has(attr):
				text_in = text_in.erase(i, attr.length() + 1)
				text_in.insert(i, target.attributes[attr])
				i = text_in.find("@", i)
			else:
				i = text_in.find("@", i + 1)
	return text_in
	
#syntax:
#query => ?{Query Text|option 1|option 2|option x|?}     ? == text input
#condition => ?{cond value to be matched;1: x;2: y;x: z;>2: greater;: defaul;} #supports compare by >,<,>=,<=
func resolve_queries_and_conditions(text_in):
	for result in query_or_cond_regex.search_all(text_in):
		var result_str = result.get_string()
		var i = result_str.find("|=")
		if i != -1:
			pass
			

#assigns values to attributes
#syntax = $hp_name = [hit points] | @hp = [5]
func assign_attributes(text_in: String, character: Character, target: Character):
	for result in assignment_regex.search_all(text_in):
		var result_str = result.get_string()
		if result_str[0] == "$": #character
			if character == null:
				continue
			var attr = attr_regex.search(result_str).get_string()
			if character.attributes.has(attr):
				character.attributes[attr][1] = value_regex.search(result_str).get_string()
				character.emit_signal("attr_updated", attr)
		else: #target
			if target == null:
				continue
			var attr = attr_regex.search(result_str).get_string()
			if target.attributes.has(attr):
				target.attributes[attr] = value_regex.search(result_str).get_string()
				target.emit_signal("attr_updated", attr)

#text_in = array with single string - pass by reference
func resolve_inner(text_in, i: int, closing_str: String, character: Character, target: Character, ignore: int = 0):
	print("inner")
	#print(text_in)
	#print(text_in[0][i])
	var attr = ""
	var attr_i = 0
	var is_attr = false
	var is_macro = false
	var is_assign = false
	
	var closing_len
	if closing_str.length() == 0: #do entire string - main
		closing_len = 1
	else:
		closing_len = closing_str.length()
	
	var last = text_in[0].substr(i, closing_len) == closing_str #for one last loop at the end
	while not last:
		if i >= text_in[0].length()-1:
			break
		if text_in[0].substr(i, closing_len) == closing_str:
			last = true #will do one more - then break
		var char = text_in[0][i]
		#print(char)
#		print(i)
		if ignore != 0: #resolving either "" or ''
			if ignore == 1: # inside ""
				if char == "'": # '' inside ""
					print("entering ' ignore")
					i = await resolve_inner(text_in, i + 1, "'", character, target, 2)
			else: # inside ''
				if char == "\"": # "" inside ''
					print("entering \" ignore")
					i = await resolve_inner(text_in, i + 1, "\"", character, target, 1)
		elif char == "'": #enter ignore state for ''
			print("entering \" ignore")
			var n = await resolve_inner(text_in, i + 1, "'", character, target, 2)
			#erase ' at begin and end
			text_in[0] = text_in[0].erase(i, 1)
			text_in[0] = text_in[0].erase(n, 1)
			i = n - 1
		elif char == "\"": #enter ignore state for ""
			print("entering \" ignore")
			var n = await resolve_inner(text_in, i + 1, "\"", character, target, 1)
			#erase " at begin and end
			print("erase: ", text_in[0][i])
			text_in[0] = text_in[0].erase(i, 1)
			print("erase: ", text_in[0][n])
			text_in[0] = text_in[0].erase(n, 1)
			i = n - 1
			print(i, " ", text_in[0][i], " ", text_in[0][i + 1])
		elif is_attr:
			if char != " " and char != "=" and char != ";" and char != "|" and char != "/" and char != ":" and char != "]" and char != "}" and char != "?":
				attr += char
			else:
				print("attr end : ", attr)
				is_attr = false
				var result = assign_start_regex.search(text_in[0].substr(i+1))
				if result != null:
					i += result.get_end()
					await assignment(text_in, i + 1, attr, character, target)
				else: #is not assignment -> replace with value
					replace_attr(text_in, attr, attr_i, character, target)
					i = attr_i-1
		elif is_macro:
			if char != " " and char != "=" and char != ";" and char != "|" and char != "/" and char != ":" and char != "]" and char != "}" and char != "?": #add char
				attr += char
			else: #replace macro with macro value + return to start
				print("macro end : ", attr)
				is_macro = false
				replace_macro(text_in, attr, attr_i, character, target)
				i = attr_i-1
		elif char == "$" or char == "@": #attribute
			print("attr")
			is_attr = true
			attr_i = i
			attr = char
		elif char == "#" or char == "%": #macro
			print("macro")
			is_macro = true
			attr_i = i #no reason to create another variables
			attr = char
		elif char == "/" and text_in[0][i + 1] == "r": #/r = roll
			print("roll")
			i -= 1
			await roll(text_in, i + 3, character, target)
		elif char == "?" and text_in[0][i + 1] == "{": #?{ = condition or query
			print(char, text_in[0][i + 1])
			print("cond or query")
			i -= 1
			await condition_or_query(text_in, i + 3, character, target)
		if not last:
			i += 1
	print("inner return")
	return i - 1

#text_in = array with single string - pass by reference
func replace_attr(text_in, attr: String, i: int, character: Character = null, target: Character = null):
	if attr[0] == "$" and character != null: #character
		if character.attributes.has(attr.substr(1)):
			print("attr found")
			replace_text(text_in, character.attributes[attr.substr(1)][1], i, attr.length())
			return
		else: #might be equipped item attribute
			var split = attr.substr(1).split(".", false)
			if split.size() > 2: #equip.slot_name.attr
				if split[0] == "equip":
					print("equip")
					print(character.equip_slots)
					var slot = find_slot(character, split[1])
					if slot != null:
						print("slot")
						if slot["item"] != null: #slot has item
							print("item")
							print(slot["item"]["attributes"], " || ", split[2])
							if slot["item"]["attributes"].has(split[2]): #item has attribute
								print("attr")
								var item_attr = slot["item"]["attributes"][split[2]]
								replace_text(text_in, slot["item"]["attributes"][split[2]]["value"], i, attr.length())
								return
						
	elif attr[0] == "@" and target != null: #target
		if target.attributes.has(attr.substr(1)):
			replace_text(text_in, target.attributes[attr.substr(1)][1], i, attr.length())
			return
		else: #might be equipped item attribute
			var split = attr.substr(1).split(".", false)
			if split.size() > 2: #equip.slot_name.attr
				if split[0] == "equip":
					var slot = find_slot(target, split[1])
					if slot != null:
						if slot["item"] != null: #slot has item
							if slot["item"]["attributes"].has(split[2]): #item has attribute
								var item_attr = slot["item"]["attributes"][split[2]]
								replace_text(text_in, slot["item"]["attributes"][split[2]]["value"], i, attr.length())
								return
	#error
	print("attr not found")
	replace_text(text_in, "<null>", i, attr.length())

func find_slot(character, slot_name):
	for slot_side_arr in character.equip_slots:
		for slot in slot_side_arr:
			if slot["name"] == slot_name:
				return slot
	return null


func replace_macro(text_in, macro: String, i: int, character: Character = null, target: Character = null):
	if macro[0] == "#" and character != null: #character macro
		if character.macros.has(macro.substr(1)):
			print("macro found")
			replace_text(text_in, character.macros[macro.substr(1)]["text"], i, macro.length())
			return
	elif macro[0] == "%" and target != null: #target macro
		if target.macros.has(macro.substr(1)):
			replace_text(text_in, target.macros[macro.substr(1)]["text"], i, macro.length())
			return
	#error
	print("macro not found")
	replace_text(text_in, "<null>", i, macro.length())

#text_in = array with single string - pass by reference
func replace_text(text_in, text: String, i: int, len: int):
	print("replace: ", text_in[0], " ", i, " ", len, " ", text)
	text_in[0] = text_in[0].erase(i, len)
	text_in[0] = text_in[0].insert(i, text)
	print("replaced: ", text_in[0])

#text_in = array with single string - pass by reference
#assigns value between [] to attribute, returns skip bool - if 
func assignment(text_in, i: int, attr: String, character: Character = null, target: Character = null):
	print("assign")
	if attr[0] == "$" and character != null: #character
		if character.attributes.has(attr.substr(1)):
			var n = await resolve_inner(text_in, i, "]", character, target)
			var sub_str = [text_in[0].substr(i, n-i+2)]
			n -= remove_marks(sub_str)
			print("assignment value: ", sub_str, " | or | ", sub_str[0])
			if sub_str[0].find("<null>") != -1 or sub_str[0].find("<expression error>") != -1: #error in assignment value - do nothing
				print("error in assignment value")
				return
			character.attributes[attr.substr(1)][1] = sub_str[0]
			character.emit_signal("attr_updated", attr.substr(1))
			return
	elif attr[0] == "@" and target != null: #target
		if target.attributes.has(attr.substr(1)):
			var n = await resolve_inner(text_in, i, "]", character, target)
			print(text_in[0])
			var sub_str = [text_in[0].substr(i, n-i+2)]
			n -= remove_marks(sub_str)
			print("assignment value: ", sub_str, " | or | ", sub_str[0])
			if sub_str[0].find("<null>") != -1 or sub_str[0].find("<expression error>") != -1: #error in assignment value - do nothing
				print("error in assignment value")
				return
			target.attributes[attr.substr(1)][1] = sub_str[0]
			target.emit_signal("attr_updated", attr.substr(1))
			return
	#error cannot access attribute - resolve and skip
	var n = await resolve_inner(text_in, i, "]", character, target)
	text_in[0].substr(i, n-i+1)
	
	
	
#text_in = array with single string - pass by reference
func roll(text_in, i: int, character: Character = null, target: Character = null):
	print("roll")
	var n = await resolve_inner(text_in, i, "//", character, target)
	print("substr: ", text_in[0].substr(i, n-i+1))
	#remove "\u001A" sequence - char marking place for hint
	var sub_str = [text_in[0].substr(i, n-i+1)]
	n -= remove_marks(sub_str)
	var res = evaluate_roll(sub_str[0])
	replace_text(text_in, res, i-2, n-i+5)
	
#text_in = array with single string - pass by reference
func condition_or_query(text_in, i: int, character: Character = null, target: Character = null):
	if text_in[0].find(";") != -1: #condition
		await condition(text_in, i, character, target)
	else: #query
		print("enter query")
		await query(text_in, i, character, target)
		print("await maybe")
		
#text_in = array with single string - pass by reference
func condition(text_in, i: int, character: Character = null, target: Character = null):
	print("cond")
	var n = await resolve_inner(text_in, i, "}", character, target)
	var sub_str = text_in[0].substr(i, n-i+1)
	print(sub_str)
	var cond_var = null
	for part in sub_str.split(";"):
		print("part = ",part)
		if cond_var == null: #first
			var part_arr = [part] #pass by reference
			remove_marks(part_arr) #remove marks if they exist
			cond_var = part_arr[0]
			print("cond var = ",cond_var)
		else:
			var part_parts = part.split(":")
			if part_parts.size() == 1: # no : -> default -> execute
				print("found - default")
				replace_text(text_in, part, i-2, n-i+4)
				return
			elif part_parts[0].begins_with("<="):
				print("part parts : ",part_parts[1])
				remove_marks(part_parts) #removes marks from part_parts[0]
				if cond_var.to_float() <= part_parts[0].substr(2).to_float():
					print("found")
					replace_text(text_in, part_parts[1], i-2, n-i+4)
					return
			elif part_parts[0].begins_with("<"):
				print("part parts : ",part_parts[1])
				remove_marks(part_parts)
				if cond_var.to_float() < part_parts[0].substr(1).to_float():
					print("found")
					replace_text(text_in, part_parts[1], i-2, n-i+4)
					return
			elif part_parts[0].begins_with(">="):
				print("part parts : ",part_parts[1])
				remove_marks(part_parts)
				if cond_var.to_float() >= part_parts[0].substr(2).to_float():
					print("found")
					replace_text(text_in, part_parts[1], i-2, n-i+4)
					return
			elif part_parts[0].begins_with(">"):
				print("part parts : ",part_parts[1])
				remove_marks(part_parts)
				if cond_var.to_float() > part_parts[0].substr(1).to_float():
					print("found")
					replace_text(text_in, part_parts[1], i-2, n-i+4)
					return
			else:
				print("part parts : ",part_parts[0], " ", cond_var)
				remove_marks(part_parts)
				if cond_var == part_parts[0]:
					print("found")
					replace_text(text_in, part_parts[1], i-2, n-i+4)
					return
	#not found
	print("not found")
	replace_text(text_in, "", i-2, n-i+4)
	return
	
#text_in = array with single string - pass by reference
func query(text_in, i: int, character: Character = null, target: Character = null):
	print("query")
	query_diag_te.visible = false
	query_diag_opt.clear()
	var n = await resolve_inner(text_in, i, "}", character, target)
	print("back at query")
	var sub_str = text_in[0].substr(i, n-i+1)
	print(sub_str)
	var first = true
	for part in sub_str.split("|"):
		print(part)
		if first: #first
			query_diag.title = part
			first = false
		else:
			if part == "?":
				query_diag_te.visible = true
				query_diag_opt.add_item("enter below", 0)
			else:
				query_diag_opt.add_item(part)
	
	if query_diag_opt.item_count == 0: #no options entered -> set textedit to visible
		query_diag_te.visible = true
		query_diag_opt.add_item("enter below", 0)
	query_diag_opt.selected = 0
	query_diag.popup()
	print("await")
	await query_diag.confirmed #wait for dialog to close
	print("await done")
	
	if query_diag_te.visible == true and query_diag_opt.get_selected_id() == 0: #set from text
		replace_text(text_in, query_diag_te.text, i-2, n-i+4)
	else:
		replace_text(text_in, query_diag_opt.get_item_text(query_diag_opt.selected) , i-2, n-i+4) #set from option vutton selection
		
func append_text(text_in):
	print("appending text: ", text_in[0])
	var mark_begin = text_in[0].find("\u001A")
	var mark_end = 0
	while mark_begin != -1:
		#append before mark
		result_node.append_text(text_in[0].substr(mark_end, mark_begin-mark_end))
		print("append = ", text_in[0].substr(mark_end, mark_begin-mark_end))
		mark_end = text_in[0].find("_", mark_begin+2) #end of mark sequence
		var num = text_in[0].substr(mark_begin + 2, mark_end - mark_begin - 2).to_int()
		print(text_in[0].substr(mark_begin + 2, mark_end - mark_begin), " = ", num)
		text_in[0] = text_in[0].erase(mark_begin, mark_end-mark_begin+1)
		print(text_in[0])
		mark_end = mark_begin + results[num].length() #end of mark sequence - for next loop
		mark_begin = text_in[0].find("\u001A")
		#append number with hint
		result_node.push_hint(roll_hints[num])
		result_node.append_text(results[num])
		result_node.pop()
	#append rest
	print("append rest = ", text_in[0].substr(mark_end, -1))
	result_node.append_text(text_in[0].substr(mark_end, -1))
	

func remove_marks(sub_str = []):
	var mark_begin = sub_str[0].find("\u001A")
	var shorter = 0
	while mark_begin != -1:
		var mark_end = sub_str[0].find("_", mark_begin+2) #end of mark sequence
		sub_str[0] = sub_str[0].erase(mark_begin, mark_end-mark_begin+1)
		shorter += mark_end-mark_begin+1
		mark_begin = sub_str[0].find("\u001A")
	return shorter


#splits command into sections - command, targeting
func split_command(text_in: String):
	var sub_str_arr = text_in.split("||")
	return sub_str_arr
	
#parses targeting string - calls proper functions in draw()
func targeting(text_in: String):
	var sub_str_arr = text_in.split(" ", false) #split into words
	var shape_arr = [] #array for shape and its dimentions
	var point_arr = [] #array for target point options
	#basic argument size check
	if sub_str_arr.size() < 3: #at least 3 arguments needed for shape
		if sub_str_arr.size() < 1 or not (sub_str_arr[0] == "self" or sub_str_arr[0] == "point"): #and not just point
			print("targeting syntax error - too short")
			return null
	#see if valid area shape
	if sub_str_arr[0] == "circle": #circle area - one argument - diameter
		shape_arr.append("circle")
		if sub_str_arr[1].is_valid_float():
			shape_arr.append(sub_str_arr[1].to_float())
			sub_str_arr = sub_str_arr.slice(2) #trim array
		else:
			print("targeting syntax error - not a number")
			return null
	elif sub_str_arr[0] == "rect": #rectangular area
		shape_arr.append("rect")
		#get rect dimentions - need one or two numbers - (x,x) or (x,y)
		if sub_str_arr[1].is_valid_float():
			shape_arr.append(sub_str_arr[1].to_float())
		else:
			print("targeting syntax error - not a number")
			return null
		if sub_str_arr[2].is_valid_float():
			shape_arr.append(sub_str_arr[2].to_float())
			sub_str_arr = sub_str_arr.slice(3) #trim array
		else: #no second number - (x,x)
			shape_arr.append(sub_str_arr[1].to_float())
			sub_str_arr = sub_str_arr.slice(2) #trim array
	elif sub_str_arr[0] == "cone": #cone area - with begin and end width
		shape_arr.append("cone")
		#get cone dimentions - need three numbers - begin-width, end-width, length
		if sub_str_arr.size() < 5: #at least 5 arguments needed for cone
			print("targeting syntax error - too short")
			return null
		if sub_str_arr[1].is_valid_float() and sub_str_arr[2].is_valid_float() and sub_str_arr[3].is_valid_float():
			shape_arr.append(sub_str_arr[1].to_float())
			shape_arr.append(sub_str_arr[2].to_float())
			shape_arr.append(sub_str_arr[3].to_float())
			sub_str_arr = sub_str_arr.slice(4) #trim array
		else:
			print("targeting syntax error - not a number")
			return null
	elif sub_str_arr[0] == "cone_angle": #cone area - with angle
		shape_arr.append("cone_angle")
		#get cone_angle dimentions - need two numbers - angle, length
		if sub_str_arr[1].is_valid_float() and sub_str_arr[2].is_valid_float():
			shape_arr.append(sub_str_arr[1].to_float())
			shape_arr.append(sub_str_arr[2].to_float())
			sub_str_arr = sub_str_arr.slice(3) #trim array
		else:
			print("targeting syntax error - not a number")
			return null
		
	#target point
	if sub_str_arr.size() < 1: #no target arguments
		print("targeting syntax error - no target arguments")
		return null
	if sub_str_arr[0] == "self": #begin from self - character token
		point_arr.append("self")
	elif sub_str_arr[0] == "point": #begin from point - might contain radius
		point_arr.append("point")
		if sub_str_arr.size() > 1:
			if sub_str_arr[1].is_valid_float():
				point_arr.append(sub_str_arr[1].to_float())
			else:
				print("targeting syntax error - invalid target radius")
				return null
	else: #not self or point
		print("targeting syntax error - invalid target argument: ", sub_str_arr[0])
		return null
	return [shape_arr, point_arr]

