#Author: Vladimír Horák
#Desc:
#Script with custom TCP client run on player peers
#used for large file transfers (images) - should be faster than using RPC

extends Node

var peer = StreamPeerTCP.new()
var connecting_func_running = false

signal recv_file(file_path)
signal connected

# Called when the node enters the scene tree for the first time.
func _ready():
	var error = 1
	connecting_func_running = true
	await connecting_func()
	emit_signal("connected")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#check for incomming data
func _process(delta):
	if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		if peer.get_available_bytes() > 0:
			var size = peer.get_u64()
			var data: PackedByteArray = peer.get_data(size)[1]
			print("Received data: ")
			var file_path = Globals.base_dir_path + data.decode_var(0)
			print("path: ", file_path)
			var len = data.decode_var_size(0)
			data = data.slice(len) #separate data from header
			var file = FileAccess.open(file_path, FileAccess.WRITE)
			if file == null:
				print("file open failed: ", FileAccess.get_open_error())
				return
			file.store_buffer(data)
			file.close()
			emit_signal("recv_file", file_path) #set file to objects waiting on file
	elif not connecting_func_running: #start connecting function
		connecting_func_running = true
		
#connect to TCP file server
func connecting_func():
	while true: #try until connection success
		var error = peer.connect_to_host(Globals.ip, 8080)
		if error == OK:
			print("TCP Connected successfully!")
			peer.poll()
			while peer.get_status() == 1:
				await get_tree().create_timer(0.5).timeout
				peer.poll()
			print("TCP status : ",peer.get_status())
			break
		else:
			print("TCP Failed to connect.")
		await get_tree().create_timer(0.5).timeout
	connecting_func_running = false

#send image to server
func send_image(file_path):
	if not FileAccess.file_exists(file_path):
		print("send image - file does not exist")
		return
	var file_name = file_path.get_file()
	var data: PackedByteArray = []
	data.resize(512)
	data.encode_var(0, ["put", file_name])
	var len = data.decode_var_size(0)
	if len < 4:
		print("path too long")
		return
	data.resize(len)
	print("data header :", data)
	data.append_array(FileAccess.get_file_as_bytes(file_path))
	send_data(data)

#request file from server
func send_file_request(file_name: String):
	var data: PackedByteArray = []
	data.resize(512)
	data.encode_var(0, ["req", file_name])
	var len = data.decode_var_size(0)
	if len < 4:
		print("path too long")
		return
	data.resize(len)
	print("data req = ", data)
	print("data req arr = ", data.decode_var(0))
	send_data(data)

func send_data(data: PackedByteArray):
	print("peer status : ", peer.get_status())
	print("sending size :", data.size())
	peer.put_u64(data.size())
	var data_print = data.slice(0, 50)
	print("sending data :", data_print)
	var err = peer.put_data(data)
	print("send err = ", err)


func _on_tree_exiting():
	peer.disconnect_from_host()
