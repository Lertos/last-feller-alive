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


#Simply here to move the parallax background
func _process(_delta):
	$Node2D/A.position.x -= 1
	$Node2D/B.position.x -= 1
	
	if $Node2D/A.position.x <= -1280:
		$Node2D/A.position.x += 1280 * 2
	elif $Node2D/B.position.x <= -1280:
		$Node2D/B.position.x += 1280 * 2


#Gets called on the server and clients when someone connects
func peer_connected(id):
	print("Peer connected: " + str(id))


#Gets called on the server and clients when someone disconnects
func peer_disconnected(id):
	print("Peer disconnected: " + str(id))


#Gets called only from client-side
func connected_to_server():
	send_player_info.rpc_id(1, $VB/PlayerName.text.lstrip(" ").rstrip(" "), multiplayer.get_unique_id(), 0, false)
	
	print("Connected to server")


#Gets called only from client-side
func connection_failed():
	print("Connection failed")


#Will send players back to the title screen and allow them to reconnect or host a new server
func server_disconnected():
	show()
	
	#Start the new song for this stage
	start_song("AudioMusicTitle")
	
	#If they are in the game or the lobby, remove them from it and put them back to the landing page
	if get_tree().root.has_node("Arena"):
		get_tree().root.get_node("Arena").queue_free()
	elif get_tree().root.has_node("Lobby"):
		get_tree().root.get_node("Lobby").queue_free()

	#Clear their multiplayer objects so it can be re-established
	peer = null
	multiplayer.multiplayer_peer = null
	GameManager.players.clear()
	
	show_help_msg("Server has been disconnected!", "See Ya!")


#Called when someone new enters the lobby
@rpc("any_peer", "call_local")
func update_lobby_with_player():
	if get_tree().root.has_node("Lobby"):
		get_tree().root.get_node("Lobby").set_players_to_spots()


#Called when someone changes their skin
@rpc("any_peer")
func update_player_skin(skin_index: int):
	var player_id = multiplayer.get_remote_sender_id()
	
	#Update their skin index so it will load properly when you join the lobby next
	if GameManager.players.has(player_id):
		GameManager.players[player_id].skin_index = skin_index
	
	#If this client is in the lobby, also update it there
	if get_tree().root.has_node("Lobby"):
		get_tree().root.get_node("Lobby").set_players_to_spots()


#Called when someone changes what screen they are in (lobby/arena)
@rpc("any_peer")
func update_current_stage(is_in_arena: bool):
	var player_id = multiplayer.get_remote_sender_id()
	
	#Update whether they are in the arena or not
	if GameManager.players.has(player_id):
		GameManager.players[player_id].is_in_arena = is_in_arena
		
	#If this client is in the lobby, also update it there
	if get_tree().root.has_node("Lobby"):
		get_tree().root.get_node("Lobby").set_player_ready(player_id)


#Handles a "disconnect" from the lobby so other players can remove them from their lobby
@rpc("any_peer", "call_local")
func player_left_lobby():
	var player_id = multiplayer.get_remote_sender_id()
	
	#If the server host disconnected; remove all players
	if player_id == 1:
		disconnect_and_remove_from_lobby()
	
	#If a client disconnects, remove their player info from the player list
	else:
		if GameManager.players.has(player_id):
			GameManager.players.erase(player_id)
			
		if player_id == multiplayer.get_unique_id():
			disconnect_and_remove_from_lobby()
		#Remove the player model from the lobby player list
		elif get_tree().root.has_node("Lobby"):
			get_tree().root.get_node("Lobby").set_players_to_spots()


#Remove the lobby node and reset all multiplayer objects
func disconnect_and_remove_from_lobby():
	if get_tree().root.has_node("Lobby"):
		await start_fade()
				
		show()
		if get_tree().root.has_node("Lobby"):
			get_tree().root.get_node("Lobby").queue_free()

	#Start the new song for this stage
	start_song("AudioMusicTitle")

	peer = null
	multiplayer.multiplayer_peer = null
	GameManager.players.clear()


#Sends info to all players when connected
@rpc("any_peer")
func send_player_info(new_player_name, id, skin_index, is_in_arena):
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"name": new_player_name,
			"id": id,
			"skin_index": skin_index,
			"is_in_arena": is_in_arena
		}
	
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_info.rpc(GameManager.players[i].name, i, GameManager.players[i].skin_index, GameManager.players[i].is_in_arena)
		#After sending all the new player info, then let the client know they can proceed to the lobby
		if id != 1:
			goto_lobby.rpc_id(id)


@rpc("call_local")
func goto_lobby():
	await load_lobby()
	get_tree().root.get_node("Lobby").set_players_to_spots()


func load_lobby():
	var scene = load("res://scenes/lobby/lobby.tscn").instantiate()
	
	await start_fade()

	get_tree().root.add_child(scene)
	hide()


func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()
	
	if not is_valid_address_and_port(): return
	if not is_name_empty(): return

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
	
	send_player_info($VB/PlayerName.text.lstrip(" ").rstrip(" "), multiplayer.get_unique_id(), 0, false)
	
	if DEBUG: load_lobby()


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	
	if not is_valid_address_and_port(): return
	if not is_name_empty(): return
		
	peer.create_client(address, port)

	#Check to make sure the connection could be established
	if peer.get_host() == null:
		show_help_msg("Connection could not be established", "Well f***")
		return
		
	peer.get_host().compress(compression_type)
	
	multiplayer.set_multiplayer_peer(peer)


func is_valid_address_and_port() -> bool:
	#Get IP address and port, or assign defaults if debugging
	address = $VB/ServerIP.text.lstrip(" ").rstrip(" ")
	port = $VB/Port.text.lstrip(" ").rstrip(" ")
	
	if address == "": address = "localhost"
	if port == "": port = "8910"
		
	#Check that the port is a valid integer or show an error
	if not port.is_valid_int():
		show_help_msg("Well, THAT doesn't seem like a valid port feller", "Get Me Out")
		return false
	
	port = port.to_int()
	return true


func start_song(song_node_name: String):
	$AudioMusicTitle.stop()
	$AudioMusicArena.stop()
	$AudioMusicLobby.stop()

	if has_node(song_node_name):
		get_node(song_node_name).play()


func is_name_empty() -> bool:
	if DEBUG: return true

	player_name = $VB/PlayerName.text.lstrip(" ").rstrip(" ")
	
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


func start_fade():
	$SceneChanger/AnimationPlayer.play("fade")
	await get_tree().create_timer(0.5).timeout
