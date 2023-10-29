extends Control

const SCENE_LOBBY_PLAYER_OTHER = preload("res://scenes/lobby/lobby_player_other.tscn")
const MAX_PLAYERS = 8
const SPACE_BETWEEN = 16


func _ready():
	$VB/Buttons/StartButton.visible = multiplayer.is_server()
	
	setup_player_spots()
	set_players_to_spots.rpc()
	

func setup_player_spots():
	var players_to_setup = MAX_PLAYERS - 1
	var space_per_player = SCENE_LOBBY_PLAYER_OTHER.instantiate().get_node("Sprite2D").texture.get_size().x + SPACE_BETWEEN
	
	for i in range(0, players_to_setup):
		var new_player = SCENE_LOBBY_PLAYER_OTHER.instantiate()
		
		new_player.visible = false
		
		$VB/Others/Players.add_child(new_player)
		
		if i % 2 == 0:
			new_player.position.x = (i / 2) * space_per_player
		elif i % 2 != 0:
			new_player.position.x -= (floor(i / 2) + 1) * space_per_player


@rpc("any_peer", "call_local")
func set_players_to_spots():
	#Hide all of the player models first, to make sure disconnected players get removed
	for i in $VB/Others/Players.get_children():
		i.visible = false

	var filled_spots = 0

	for i in GameManager.players:
		if GameManager.players[i].id != multiplayer.get_unique_id():
			var player_spot = $VB/Others/Players.get_child(filled_spots)
			
			player_spot.name = str(GameManager.players[i].id)
			player_spot.set_player_name(GameManager.players[i].name)
			player_spot.change_skin(GameManager.players[i].skin_index)
			player_spot.visible = true
			
			filled_spots += 1


@rpc("any_peer")
func change_players_skin(id, skin_index):
	if id == multiplayer.get_unique_id():
		return
	
	for i in $VB/Others/Players.get_children():
		#If we find an invisible child we know there are no spots left to change
		if not i.visible:
			return
		
		if i.name == str(id):
			i.change_skin(skin_index)
			GameManager.players[id].skin_index = skin_index
			return


@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://main.tscn").instantiate()

	get_tree().root.add_child(scene)
	self.hide()


func _on_start_button_pressed():
	start_game.rpc()


func _on_leave_button_pressed():
	var multiplayer_manager = get_tree().root.get_node("MultiplayerManager")
	
	multiplayer_manager.show()
	multiplayer_manager.player_left_Lobby.rpc()

	queue_free()
	
