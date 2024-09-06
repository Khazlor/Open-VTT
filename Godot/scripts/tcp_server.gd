#Author: Vladimír Horák
#Desc:
#Script for TCP server - used for large file transfers (images)
#running in separate thread on server

extends Node

var tcp_server: TCPServer
var thread = Thread.new()
var run_thread = true
var peer_pool = []

#var peer_data_dict = {}

signal recv_file(file_name)

# Called when the node enters the scene tree for the first time.
func _ready():
	#launch TCP server for file transfer
	tcp_server = TCPServer.new()
	if tcp_server.listen(8080) == OK:
		start_async_server()
		print("TCP server started")
	else:
		print("Failed to start TCP server")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#check for connecting and disconnecting peers
func _process(delta):
	if tcp_server.is_connection_available():
		var client = tcp_server.take_connection()
		peer_pool.append(client)
		print("Client has connected")
	for i in range(len(peer_pool)):
		var peer = peer_pool[i]
		#check if still connected
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			peer_pool.remove(i)
			print("Client has disconnected")

func start_async_server():
	thread.start(_thread_function)

#check for incomming data
func _thread_function():
	while run_thread:
		for peer in peer_pool:
			if peer.get_available_bytes() > 0:
				#var av_bytes = peer.get_available_bytes()
				##if not peer_data_dict.has(peer): #new transfer
					##var data_header_arr = process_header(data)
					##var full_data: PackedByteArray = []
					##peer_data_dict[peer] = [data_header_arr, full_data]
				##var peer_data = peer_data_dict[peer]
				##var size_to_get = max(peer_data[0][0], )#max of transfer size and 
				#var data = peer.get_data(av_bytes)
				#var header_arr = process_header(data)
				#if header_arr[0] > av_bytes: #more data to be received
					#data.append_array(peer.get_data(header_arr[0] - av_bytes))
				#elif header_arr[0] < av_bytes: #more data was received
					#data.append_array(peer.get_data(header_arr[0] - av_bytes))
				#else all data was received
				var size = peer.get_u64()
				var data = peer.get_data(size)
				print("data found")
				print("got data: ")
				process_data(data[1], peer)
		OS.delay_msec(500)
			
		
#func process_header(data: PackedByteArray):
	#var data_arr = data.decode_var(0)
	#print("server received data header: ", data_arr)
	##var size = data_arr[0]
	##var type = data_arr[1]
	##var file_name = data_arr[2]
	#return data_arr
	
#process incoming data - upload / request
func process_data(data: PackedByteArray, peer):
	var print_data = data.slice(0, 100)
	print("recv data: ", print_data)
	var data_arr = data.decode_var(0)
	print("server received data: ", data_arr[0])
	if data_arr[0] == "req":
		#send requested data
		var file_path = "/images/" + Globals.campaign.campaign_name + "/" + data_arr[1]
		var full_file_path = Globals.base_dir_path + file_path
		print("received request for: ", full_file_path)
		if FileAccess.file_exists(full_file_path):
			var s_data: PackedByteArray = []
			s_data.resize(1024)
			s_data.encode_var(0, file_path)
			var len = s_data.decode_var_size(0)
			if len < 4:
				print("path too long")
				return
			s_data.resize(len)
			var file_data = FileAccess.get_file_as_bytes(full_file_path)
			if not file_data.is_empty(): #file was created in rcp but data was not yet uploaded
				s_data.append_array(file_data)
				send_data(s_data, peer)
			else:
				print("file is empty: ", full_file_path)
		else:
			print("request - file does not exist: ", full_file_path)
	elif data_arr[0] == "put":
		print("put")
		#recieve sent data - create image in folder
		var file_path = Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name + "/" + data_arr[1]
		#if FileAccess.file_exists(file_path): - done in rpc
			#name = rename_file(name)
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		var len = data.decode_var_size(0)
		var file_data = data.slice(len) #separate data from header
		print("file data: ", file_data.slice(0, 50))
		print("data len: ", file_data.size())
		file.store_buffer(file_data)
		file.close()
		print("file len: ", file.get_length())
		#response with new name - done in rpc
		#peer.put_data(name)
		#TODO received file on server - check waiting objects, notify peers
		emit_signal("recv_file", data_arr[1])


func send_data(data: PackedByteArray, peer):
	print("sending data")
	print("sending size :", data.size())
	peer.put_u64(data.size())
	var data_print = data.slice(0, 50)
	print("sending data :", data_print)
	var err = peer.put_data(data)
	print("send err = ", err)
	

func rename_file(old_name):
	var name = old_name
	var i = 2
	var ind = old_name.rfind(".")
	while FileAccess.file_exists(Globals.base_dir_path + "/images/" + Globals.campaign.campaign_name + "/" + name):
		name = old_name.insert(ind, "_" + str(i))
		print(name)
		i += 1
	return name


func _on_tree_exiting():
	run_thread = false
	thread.wait_to_finish()
