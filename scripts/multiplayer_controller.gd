extends Control

""" RPC breakdown
any_peer - sends on ALL connected peers (everyone will call that function locally)
authority - only when the authority calls the function, will it go out for everyone else to call it
call_local - when I call that RPC, I will also call that function on my end
call_remote - when I call that RPC, only remote peers will call it
reliable - uses TCP; slower but reliable
unreliable - uses UDP; fast but unreliable
unreliable_ordered - same as unreliable - but each piece of data comes in the correct order
"""

const DEBUG = true

var address
var port
var player_name

@onready var popup_initial_size = $AcceptDialog.size
@onready var popup_initial_pos = $AcceptDialog.position

var peer
var compression_type = ENetConnection.COMPRESS_RANGE_CODER


func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)

#Gets called on the server and clients when someone connects
func peer_connected(id):
	print("Peer connected: " + str(id))


#Gets called on the server and clients when someone disconnects
func peer_disconnected(id):
	print("Peer disconnected: " + str(id))


func server_disconnected():
	self.show()
	get_tree().root.get_node("Arena").queue_free()
	multiplayer.multiplayer_peer = null
	
	show_help_msg("Server has been disconnected!", "Guess I'll Go")
	
	GameManager.players.clear()


@rpc("any_peer", "call_local")
func player_left_Lobby():
	var player_id = multiplayer.get_remote_sender_id()
	
	if player_id == multiplayer.get_unique_id():
		multiplayer.multiplayer_peer = null
		GameManager.players.clear()
	else:
		if GameManager.players.has(player_id):
			GameManager.players.erase(player_id)


#Gets called only from client-side
func connected_to_server():
	send_player_info.rpc_id(1, $VB/PlayerName.text, multiplayer.get_unique_id(), 0)
	
	print("Connected to server")


#Gets called only from client-side
func connection_failed():
	print("Connection failed")


#Sends info to all players when connected
@rpc("any_peer")
func send_player_info(name, id, skin_index):
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"name": name,
			"id": id,
			"skin_index": skin_index
		}
	
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_info.rpc(GameManager.players[i].name, i, GameManager.players[i].skin_index)
		#After sending all the new player info, then let the client know they can proceed to the lobby
		if id != 1:
			goto_lobby.rpc_id(id)


@rpc("call_local")
func goto_lobby():
	load_lobby()
	get_tree().root.get_node("Lobby").set_players_to_spots()


func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()

	if not is_valid_address_and_port():
		return
		
	if not is_name_empty():
		return

	var error = peer.create_server(port, 8)
	
	if error != OK:
		show_help_msg("Server creation failed!", "Have Mercy")
		return
	else:
		if not DEBUG:
			show_help_msg("Server created! Press Start", "Woohoo!")
	
	#Makes bandwidth usage a little more efficient
	peer.get_host().compress(compression_type)
	
	#Use the host connection as the local peer
	multiplayer.set_multiplayer_peer(peer)
	
	print("Server has been created. Waiting for players")
	
	send_player_info($VB/PlayerName.text, multiplayer.get_unique_id(), 0)
	
	if DEBUG:
		load_lobby()


func load_lobby():
	var scene = load("res://scenes/lobby/lobby.tscn").instantiate()
	
	get_tree().root.add_child(scene)
	self.hide()


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	
	if not is_valid_address_and_port():
		return
	
	if not is_name_empty():
		return
		
	peer.create_client(address, port)

	#Check to make sure the connection could be established
	if peer.get_host() == null:
		show_help_msg("Connection could not be established", "Well f***")
		return
		
	peer.get_host().compress(compression_type)
	
	multiplayer.set_multiplayer_peer(peer)


func is_valid_address_and_port() -> bool:
	#Get IP address and port, or assign defaults if debugging
	address = $VB/ServerIP.text
	port = $VB/Port.text
	
	if address == "":
		address = "localhost"
	if port == "":
		port = "8910"
		
	#Check that the port is a valid integer or show an error
	if not port.is_valid_int():
		show_help_msg("Well, THAT doesn't seem like a valid port feller", "Get Me Out")
		return false
	
	port = port.to_int()
	return true


func is_name_empty() -> bool:
	if DEBUG:
		return true

	player_name = $VB/PlayerName.text
	
	if player_name == "":
		show_help_msg("You need a name dude", "Be Obedient")
		return false

	return true


func _on_accept_dialog_visibility_changed():
	$PopupHelper.visible = $AcceptDialog.visible


func show_help_msg(message: String, button_text: String):
	$AcceptDialog.dialog_text = message
	$AcceptDialog.ok_button_text = button_text
	$AcceptDialog.reset_size()
	$AcceptDialog.popup_centered()
