#Author: Vladimír Horák
#Desc:
#Script for controlling main game scene to which map scenes are loaded - handles multiplayer map loading

extends Node2D

var map_comp = preload("res://scenes/map.tscn")
var map
var tcp_server_comp = preload("res://components/tcp_server.tscn")
var tcp_server
var tcp_client_comp = preload("res://components/tcp_client.tscn")
var tcp_client
var request_id = 0 #counter to differenciate between multiple simultaneous file_checks

var undo_stack = []
var undo_stack_pos = -1
enum undo_types {CREATE, REMOVE, MODIFY, MODIFY_ATTRIBUTE}

var objects_waiting_for_file = {}

signal file_check_done(upload, file_name, id)


func _enter_tree():
	Globals.lobby = self

# Called when the node enters the scene tree for the first time.
func _ready():
	#multiplayer.allow_object_decoding = true
	#print("path: ",Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name)
	#create image folder if it does not exists
	if map != null:
		map._on_child_exiting_tree(map.get_child(-1))
		map.queue_free()
	if Globals.enet_peer != null: #multiplayer
		if multiplayer.is_server(): #server
			if not DirAccess.dir_exists_absolute(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name):
				DirAccess.make_dir_recursive_absolute(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name)
			#start tcp server for file transfer:
			if tcp_server == null:
				tcp_server = tcp_server_comp.instantiate()
				tcp_server.connect("recv_file", on_tcp_server_recv_file)
				add_child(tcp_server)

			map = map_comp.instantiate()
			if has_node("Map"):
				remove_child(get_node("map"))
			add_child(map)
			map.name = "Map"
			#set all connected peers to this map
			var file_buffer = FileAccess.get_file_as_bytes(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + Globals.new_map.map_name)
			var file_buffer_size = file_buffer.size()
			file_buffer = file_buffer.compress()
			client_set_map.rpc(file_buffer, file_buffer_size)

		else: #client
			Globals.client = true
			tcp_client = tcp_client_comp.instantiate()
			tcp_client.connect("recv_file", on_tcp_client_recv_file)
			tcp_client.connect("connected", on_tcp_client_connected)
			add_child(tcp_client)
	else: #singleplayer
		map = map_comp.instantiate()
		if has_node("Map"):
			remove_child(get_node("map"))
		add_child(map)
		map.name = "Map"

#for checking inside a resource
func check_is_server():
	if multiplayer.multiplayer_peer != null:
		return multiplayer.is_server()
	return true

func on_tcp_client_connected(): #connected to server with loaded scene - load map
	server_get_map.rpc_id(1)

func on_tcp_server_recv_file(file_name):
	var file_path = Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name + "/" + file_name
	server_recvd_file.rpc(file_name) #notify all peers that new file was uploaded to server
	on_tcp_client_recv_file(file_path) #check if any objects on server need file

@rpc("authority", "call_remote", "reliable")
func server_recvd_file(file_name):
	print("check waiting objects for file")
	if objects_waiting_for_file.has(file_name):
		print("object found - download file")
		tcp_client.send_file_request(file_name)
	else:
		print("no object waiting for file")

@rpc("authority", "call_remote", "reliable")
func remove_map():
	map.queue_free()

func on_tcp_client_recv_file(file_path):
	print("client got file - check waiting objects for file")
	var file_name = file_path.get_file()
	if objects_waiting_for_file.has(file_name):
		var texture: Texture2D = Globals.load_texture(file_path)
		if texture != null:
			print("texture is valid")
			var obj_arr = objects_waiting_for_file[file_name]
			for object in obj_arr:
				print("setting texture on object", object)
				var type = object.get_meta("type")
				if type == "rect": #set style
					print("object is rect", object)
					var style = object.get_theme_stylebox("panel")
					style.texture = texture
					object.add_theme_stylebox_override("panel", style)
					print("texture sizes: ", style.texture.get_size(), texture.get_size(), object.get_theme_stylebox("panel").texture.get_size())

				elif type == "token": #set token texture
					object.character.token_texture = file_path
					object.token_polygon.update_token(false)
			objects_waiting_for_file.erase(file_name)
		else:
			print("texture is null - not valid image")
	else:
		print("no object waiting for file")


@rpc("any_peer", "call_remote", "reliable")
func server_get_map():
	if multiplayer.is_server(): #just to be sure
		var sender_id = multiplayer.get_remote_sender_id()
		print("returtning", map)
		var layers = $Map/Draw/Layers
		if layers != null:
			Globals.new_map.save_map(layers)
			#var file = FileAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + Globals.new_map.map_name, FileAccess.READ)
			#var file_buffer = file.get_buffer(file.get_length())
			var file_buffer = FileAccess.get_file_as_bytes(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + Globals.new_map.map_name)
			var file_buffer_size = file_buffer.size()
			file_buffer = file_buffer.compress()
			#call_rpc_client_set_map(sender_id, file_buffer, file_buffer_size)
			client_set_campaign.rpc_id(sender_id, Globals.campaign.campaign_name)
			client_set_map.rpc_id(sender_id, file_buffer, file_buffer_size)

func call_rpc_client_set_map(sender_id, file_buffer, file_buffer_size):
	client_set_map.rpc_id(sender_id, file_buffer, file_buffer_size)

@rpc("authority", "call_remote", "reliable")
func client_set_campaign(campaign_name):
	if Globals.campaign == null:
		Globals.campaign = Campaign_res.new()
	Globals.campaign.campaign_name = campaign_name
	#create image folder if it does not exists
	if not DirAccess.dir_exists_absolute(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name):
		DirAccess.make_dir_recursive_absolute(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name)


@rpc("authority", "call_remote", "reliable")
func client_set_map(server_map_file_buffer, file_buffer_size):
	if map != null: #free old map
		remove_child(map)
		map.queue_free()
	print(multiplayer.get_unique_id(), " client set map")
	server_map_file_buffer = server_map_file_buffer.decompress(file_buffer_size)
	var file = FileAccess.open(Globals.base_dir_path + "/temp.file", FileAccess.WRITE_READ)
	file.store_var(server_map_file_buffer)
	file.flush()
	print("set ", file.get_length())
	file.seek(12)#skip buffer header probably created by FileAccess get_file_as_bytes or get_buffer
	Globals.new_map = Map_res.new()
	Globals.map = Globals.new_map
	map = map_comp.instantiate()
	Globals.draw_layer = map.get_node("Draw/Layers")
	Globals.new_map.load_map("", true, file)
	file.close()
	if has_node("Map"):
		remove_child(get_node("map"))
	add_child(map)
	map.name = "Map"

	#tutorial
	if Globals.campaign == null:
		Globals.campaign = Campaign_res.new()
	if Globals.campaign.tutorial:
		Globals.draw_comp.get_node("TutorialWindow").popup()
		Globals.campaign.tutorial = false

#call on server to request file
@rpc("any_peer", "call_remote", "reliable")
func tcp_server_get_file(path):
	var peer_id = multiplayer.get_remote_sender_id()
	pass

#check server files for file - based on name and hash
#if file with same name and different hash exists - creates new file, under new name
#returns true if same file already exists, false if not and file should be uploaded, and filename which should be used
@rpc("any_peer", "call_local", "reliable")
func check_file_on_server(file_name, file_hash, id):
	var peer_id = null
	if multiplayer.multiplayer_peer != null:
		peer_id = multiplayer.get_remote_sender_id()
	print("peer :", peer_id)
	var new_file_name = file_name
	var ext_pos = file_name.rfind(".") #find end of file name - before extension (image|.png)
	var i = 1
	while FileAccess.file_exists(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name + "/" + new_file_name):
		if file_hash == FileAccess.get_md5(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name + "/" + new_file_name):
			#same file - do not upload:
			if peer_id != null:
				check_file_on_server_response.rpc_id(peer_id, true, new_file_name, id)
			return [false, new_file_name, id]
		else:
			new_file_name = file_name.insert(ext_pos, "_" + str(i))
			i += 1
	#else not found - create file:
	var new_file = FileAccess.open(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name + "/" + new_file_name, FileAccess.WRITE)
	if new_file == null:
		print("error opening file: ", FileAccess.get_open_error())
	new_file.close()
	if peer_id != null:
		check_file_on_server_response.rpc_id(peer_id, false, new_file_name, id)
	return [true, new_file_name, id]


@rpc("authority", "call_local", "reliable")
func check_file_on_server_response(exists: bool, file_name, id):
	print("emit file check done")
	if multiplayer.is_server():
		await get_tree().create_timer(0.1).timeout
	emit_signal("file_check_done", not exists, file_name, id)

#coroutine checks server for file, handles upload, returns file_path to use locally for file
func handle_file_transfer(file_path: String, set_image = true):
	print("handle file transfer")
	if FileAccess.file_exists(file_path):
		print("file exists")
		var file_name = file_path.get_file()
		var file_hash = FileAccess.get_md5(file_path)
		var id = request_id
		request_id += 1
		var recv_id = null
		var first = true
		var result
		print("entering while")
		if multiplayer.multiplayer_peer != null:
			while recv_id != id: #wait for signal with correct id
				if first:
					first = false
					check_file_on_server.rpc_id(1, file_name, file_hash, id)
				result = await file_check_done
				recv_id = result[2]
		else:
			result = check_file_on_server(file_name, file_hash, id)
		print("signal recvd")
		var new_file_path = Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name + "/" + result[1]
		if result[0] == true: #upload
			if tcp_client != null: #client
				tcp_client.send_image(file_path)
			elif tcp_server != null: #server
				DirAccess.copy_absolute(file_path, new_file_path)
				tcp_server.emit_signal("recv_file", result[1])
			else: #local
				DirAccess.copy_absolute(file_path, new_file_path)
		if set_image: #set image locally
			if not FileAccess.file_exists(new_file_path):
				print("file does not exist - copy file")
				DirAccess.copy_absolute(file_path, new_file_path)
			else:
				print("file already exists")
		return new_file_path
	else:
		print("handle file transfer - file does not exist")

#adds object that does not have (image) file yet to list of objects waiting for file
func add_to_objects_waiting_for_file(file_name: String, object):
	print("adding ", object, " to waiting")
	if objects_waiting_for_file.has(file_name):
		objects_waiting_for_file[file_name].append(object)
	else:
		objects_waiting_for_file[file_name] = [object]
	print("objects waiting: ", objects_waiting_for_file)

# ============================ UNDO / REDO ===============================

func add_operation_to_undo_stack(undo_arr):
	var begin = undo_stack_pos - Globals.undo_size + 1
	if begin < 0:
		begin = 0
	undo_stack = undo_stack.slice(begin, undo_stack_pos + 1)
	undo_stack.append(undo_arr)
	undo_stack_pos = undo_stack.size()-1
	#print("before_slice:", undo_stack)
	print("undo stack ", undo_stack_pos)
	print("after_slice:", undo_stack)
	
	
func add_operation_part_to_undo_stack(undo_arr):
	undo_stack[-1][1].append(undo_arr)
	
func undo_operation():
	print("undo ", undo_stack_pos)
	print("after_slice:", undo_stack)
	if undo_stack_pos == -1:
		print("nothing to undo")
		return
	var operation = undo_stack[undo_stack_pos]
	if operation[0] == undo_types.CREATE:
		#undo create == remove objects
		for object_arr in operation[1]:
			if object_arr[0] != null:
				Globals.draw_comp.remove_object(object_arr[0])
	elif operation[0] == undo_types.REMOVE:
		#undo REMOVE == create objects
		for object_arr in operation[1]:
			if object_arr[0] == null:
				object_arr[0] = Globals.draw_comp.create_object(object_arr[1], object_arr[2], object_arr[3])
				Globals.draw_comp.create_object_on_remote_peers(object_arr[0])
	elif operation[0] == undo_types.MODIFY:
		#undo MODIFY == load original values
		for object_arr in operation[1]:
			
			Globals.draw_comp.synch_object_properties(object_arr[0], object_arr[2])
			Globals.draw_comp.synch_object_properties.rpc(object_arr[0], object_arr[2])
	elif operation[0] == undo_types.MODIFY_ATTRIBUTE:
		#undo MODIFY_ATTRIBUTE == load original values to character attribute
		for object_arr in operation[1]:
			if object_arr[0] != null:
				for attr_arr in object_arr[1]:
					object_arr[0].attributes[attr_arr[0]] = attr_arr[2]
					object_arr[0].emit_signal("attr_updated", attr_arr[0], false)
	undo_stack_pos -= 1
		
func redo_operation():
	print("redo ", undo_stack_pos)
	print("after_slice:", undo_stack)
	if undo_stack_pos == undo_stack.size() - 1:
		print("nothing to redo")
		return
	var operation = undo_stack[undo_stack_pos + 1]
	if operation[0] == undo_types.CREATE:
		#redo create == create removed objects
		for object_arr in operation[1]:
			if object_arr[0] == null:
				object_arr[0] = Globals.draw_comp.create_object(object_arr[1], object_arr[2], object_arr[3])
				Globals.draw_comp.create_object_on_remote_peers(object_arr[0])
	elif operation[0] == undo_types.REMOVE:
		#redo REMOVE == remove objects
		for object_arr in operation[1]:
			if object_arr[0] != null:
				Globals.draw_comp.remove_object(object_arr[0])
	elif operation[0] == undo_types.MODIFY:
		#redo MODIFY == load new values
		for object_arr in operation[1]:
			Globals.draw_comp.synch_object_properties(object_arr[0], object_arr[1])
			Globals.draw_comp.synch_object_properties.rpc(object_arr[0], object_arr[1])
	elif operation[0] == undo_types.MODIFY_ATTRIBUTE:
		#undo MODIFY_ATTRIBUTE == load new values to character attribute
		for object_arr in operation[1]:
			if object_arr[0] != null:
				for attr_arr in object_arr[1]:
					object_arr[0].attributes[attr_arr[0]] = attr_arr[1]
					object_arr[0].emit_signal("attr_updated", attr_arr[0], false)
	undo_stack_pos += 1
