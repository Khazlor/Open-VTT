extends Node

var tcp_server: TCPServer
var thread = Thread.new()
var peer_pool = []

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
#check if for connecting and disconnecting peers
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

func _thread_function():
	while true:
		print("check for data")
		for peer in peer_pool:
			print("peer data len: ", peer.get_available_bytes())
			if peer.get_available_bytes() > 0:
				print("data found")
				var data = peer.get_data(peer.get_available_bytes())
				print("got data: ", data)
				process_data(data[1], peer)
		OS.delay_msec(500)
			
		
func process_data(data: PackedByteArray, peer):
	print("recv data: ", data)
	var data_arr = data.decode_var(0)
	print("server received data: ", data_arr[0])
	if data_arr[0] == "req":
		#send requested data
		var path = data_arr[1]
		if FileAccess.file_exists(path):
			peer.put_data(FileAccess.get_file_as_bytes(path))
	elif data_arr[0] == "put":
		print("put")
		#recieve sent data - create image in folder
		var name = data_arr[1]
		if FileAccess.file_exists("res://images/" + name):
			name = rename_file(name)
		var file = FileAccess.open("res://images/" + name, FileAccess.WRITE)
		print(name)
		var len = data.decode_var_size(0)
		var file_data = data.slice(len)
		print("file data: ", file_data)
		print("data len: ", file_data.size())
		file.store_buffer(file_data)
		print("file len: ", file.get_length())
		#response with new name
		#peer.put_data(name)


func rename_file(old_name):
	var name = old_name
	var i = 2
	var ind = old_name.rfind(".")
	while FileAccess.file_exists("res://images/" + name):
		name = old_name.insert(ind, "_" + str(i))
		print(name)
		i += 1
	return name
