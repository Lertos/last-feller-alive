extends Node2D

enum EVENT_TYPE {NONE, BEAM, BOMB, GRAVITY_FIELD} #PULL_FIELD
enum SPECIAL_EVENT_TYPE {NONE, MULTI_BEAM, BOMB_STRING, ZERO_GRAVITY} #CANNON_PULL

#Objects to spawn
const SCENE_PLAYER = preload("res://scenes/player.tscn")
const SCENE_WALL = preload("res://scenes/wall.tscn")
const SCENE_BEAM = preload("res://scenes/beam.tscn")
const SCENE_BOMB = preload("res://scenes/bomb.tscn")
const SCENE_CANNON = preload("res://scenes/cannon.tscn")
const SCENE_GRAVITY_FIELD = preload("res://scenes/gravity_field.tscn")
const SCENE_PULL_FIELD = preload("res://scenes/pull_field.tscn")

const SCENE_WIN_TEXT = preload("res://win_text.tscn")

@onready var multiplayer_manager = get_tree().root.get_node("MultiplayerManager")

var cannon_list: Array[Node] = []
var coordinates_for_cannons: Array[Vector2] = []
var available_coordinates_for_cannons: Array[Vector2] = []

#Used to dynamically grab the correct settings for the difficulty
var difficulty_settings = {
	Enum.DIFFICULTY.EASY: {
		"initial_spawn_time": 4.0,
		"time_decrease_per_cannon": 0.25,
		"events_before_cannon": 4,
		"special_events_per_cannon": 1
	},
	Enum.DIFFICULTY.MEDIUM: {
		"initial_spawn_time": 3.0,
		"time_decrease_per_cannon": 0.25,
		"events_before_cannon": 4,
		"special_events_per_cannon": 2
	},
	Enum.DIFFICULTY.HARD: {
		"initial_spawn_time": 2.0,
		"time_decrease_per_cannon": 0.5,
		"events_before_cannon": 3,
		"special_events_per_cannon": 2
	}
}

#Arena configuration variables
var distance_from_walls = Config.wall_width

#Variables to keep track of game state
var total_events_since_cannon: int = 0
var special_events_since_cannon: int = 0

var rng = RandomNumberGenerator.new()

#Keep track of the next event
var countdown_timer: int = 4
var next_normal_event_enum: EVENT_TYPE = EVENT_TYPE.NONE
var next_special_event_enum: SPECIAL_EVENT_TYPE = SPECIAL_EVENT_TYPE.NONE
var next_event_pos = []
var next_beam_angles = []


func _ready():
	#Set the initial time for spawning to start
	$SpawnerTimer.wait_time = difficulty_settings[Config.chosen_difficulty]["initial_spawn_time"]
	$SpawnerTimer.timeout.connect(spawn_object)
	
	setup_arena_walls()
	setup_cannon_spots()
	setup_players()
	
	$SpawnerTimer.start()

	#To ensure the synchronizers have enough time to create themselves
	$StartCountdown.wait_time = 1.0
	$StartCountdown.timeout.connect(start_timer_countdown)
	$StartCountdown.start()


func start_timer_countdown():
	countdown_timer -= 1
	
	#When the game starts, initialize and set the synchronizers to active
	if countdown_timer == 0:
			$CountdownLabel.text = "GO"
	elif countdown_timer > 0:
		$CountdownLabel.text = str(countdown_timer)
	elif countdown_timer < 0:
		for player_node in $Players.get_children():
			player_node.get_node("MultiplayerSynchronizer").public_visibility = true
			player_node.is_paused = false
			
		$StartCountdown.stop()
		$CountdownLabel.visible = false


func queue_next_event():
	#Only run if the server host. This "queues" the event, and syncs the variables so everyone spawns it correctly
	if multiplayer.get_unique_id() == 1:
		#If the counter is at 0, spawn a cannon. This is so we can keep count and just reset easily
		if total_events_since_cannon == 0:
			queue_cannon()
			
			sync_variables.rpc(next_normal_event_enum, next_special_event_enum, next_event_pos, next_beam_angles)
			
			total_events_since_cannon += 1
			return
		
		#Figure out if it's a special event or normal event, then spawn it
		var is_special_event: bool = (rng.randi() % 2 == 0)
		
		if special_events_since_cannon >= difficulty_settings[Config.chosen_difficulty]["special_events_per_cannon"]:
			is_special_event = false
		
		#If special event
		if is_special_event:
			next_special_event_enum = rng.randi_range(1, SPECIAL_EVENT_TYPE.size() - 1)

			match next_special_event_enum:
				SPECIAL_EVENT_TYPE.MULTI_BEAM:
					queue_special_multi_beam()
				SPECIAL_EVENT_TYPE.BOMB_STRING:
					queue_special_bomb_string()
				SPECIAL_EVENT_TYPE.ZERO_GRAVITY:
					queue_special_zero_gravity()
				#SPECIAL_EVENT_TYPE.CANNON_PULL:
				#	queue_special_cannon_pull()

			special_events_since_cannon += 1
		#If normal event
		else:
			next_normal_event_enum = rng.randi_range(1, EVENT_TYPE.size() - 1)

			match next_normal_event_enum:
				EVENT_TYPE.BEAM:
					next_beam_angles.append(rng.randf_range(0.0, 359.9))
					queue_event_at_random(distance_from_walls * 2)
				EVENT_TYPE.BOMB:
					queue_event_at_random(distance_from_walls * 2)
				EVENT_TYPE.GRAVITY_FIELD:
					queue_event_at_random(distance_from_walls * 2)
				#EVENT_TYPE.PULL_FIELD:
				#	queue_event_at_random(distance_from_walls * 2)

		#Increase the counters
		if total_events_since_cannon >= difficulty_settings[Config.chosen_difficulty]["events_before_cannon"]:
			total_events_since_cannon = 0
			special_events_since_cannon = 0
		else:
			total_events_since_cannon += 1
			
		sync_variables.rpc(next_normal_event_enum, next_special_event_enum, next_event_pos, next_beam_angles)


@rpc("call_remote")
func sync_variables(normal_event_enum: EVENT_TYPE, special_event_enum: SPECIAL_EVENT_TYPE, event_pos, beam_angles):
	next_normal_event_enum = normal_event_enum
	next_special_event_enum = special_event_enum
	next_event_pos = event_pos
	next_beam_angles = beam_angles


func spawn_object():
	#If special event
	if next_special_event_enum != SPECIAL_EVENT_TYPE.NONE:
		match next_special_event_enum:
			SPECIAL_EVENT_TYPE.MULTI_BEAM:
				spawn_special_multi_beam()
			SPECIAL_EVENT_TYPE.BOMB_STRING:
				spawn_special_bomb_string()
			SPECIAL_EVENT_TYPE.ZERO_GRAVITY:
				spawn_special_zero_gravity()
			#SPECIAL_EVENT_TYPE.CANNON_PULL:
			#	spawn_special_cannon_pull()
	#If normal event
	elif next_normal_event_enum != EVENT_TYPE.NONE:
		match next_normal_event_enum:
			EVENT_TYPE.BEAM:
				spawn_event_at_pos(next_event_pos, SCENE_BEAM, $Beams, [next_beam_angles[0]])
			EVENT_TYPE.BOMB:
				spawn_event_at_pos(next_event_pos, SCENE_BOMB, $Bombs)
			EVENT_TYPE.GRAVITY_FIELD:
				spawn_event_at_pos(next_event_pos, SCENE_GRAVITY_FIELD, $GravityFields)
			#EVENT_TYPE.PULL_FIELD:
			#	spawn_event_at_pos(next_event_pos, SCENE_PULL_FIELD, $PullFields)
	#If a cannon is spawning
	else:
		spawn_cannon()
	
	#Reset the variables so we know what to spawn next
	next_normal_event_enum = EVENT_TYPE.NONE
	next_special_event_enum = SPECIAL_EVENT_TYPE.NONE
	next_event_pos.clear()
	next_beam_angles.clear()
	
	#Will only run on the host
	await get_tree().create_timer(0.3).timeout
	queue_next_event()


func queue_cannon():
	if available_coordinates_for_cannons.size() == 0:
		return
	
	var rand_index = rng.randi_range(0, available_coordinates_for_cannons.size() - 1)
	
	next_event_pos.append(available_coordinates_for_cannons[rand_index])
	available_coordinates_for_cannons.remove_at(rand_index)


func spawn_cannon():
	#Upgrade all current cannons
	for cannon in cannon_list:
		cannon.upgrade_cannon()
		
	if available_coordinates_for_cannons.size() == 0 or next_event_pos.size() == 0:
		return
	
	var cannon_pos = next_event_pos[0]
	var new_cannon = SCENE_CANNON.instantiate()

	$Cannons.add_child(new_cannon)
	
	new_cannon.position = cannon_pos
		
	cannon_list.append(new_cannon)
	
	$SpawnerTimer.stop()
	$SpawnerTimer.wait_time = max($SpawnerTimer.wait_time - difficulty_settings[Config.chosen_difficulty]["time_decrease_per_cannon"], 1.0)
	$SpawnerTimer.start()


func queue_event_at_random(padding: int):
	var left_top_corner = Vector2(padding, padding)
	var bottom_right_corner = Vector2(Config.arena_width - padding, Config.arena_height - padding)
	
	var x = rng.randi_range(left_top_corner.x, bottom_right_corner.x)
	var y = rng.randi_range(left_top_corner.y, bottom_right_corner.y)
	
	next_event_pos.append(Vector2(x, y))


func spawn_event_at_pos(positions: Array, event_scene: PackedScene, parent_node: Node, spawn_angle = []):
	for event in positions:
		var new_event = event_scene.instantiate()

		parent_node.add_child(new_event)
		
		new_event.position = event
		
		if spawn_angle != []:
			new_event.rotation = spawn_angle[0]


#Spawns multiple beams back to back with a slight time inbetween
func queue_special_multi_beam():
	for i in range (0,4):
		next_beam_angles.append(rng.randf_range(0.0, 359.9))
		queue_event_at_random(distance_from_walls * 2)


#Spawns multiple beams back to back with a slight time inbetween
func spawn_special_multi_beam():
	var spawn_positions = next_event_pos.duplicate()
	var spawn_angles = next_beam_angles.duplicate()
	
	for index in range(0, spawn_positions.size()):
		spawn_event_at_pos([spawn_positions[index]], SCENE_BEAM, $Beams, [spawn_angles[index]])
		await get_tree().create_timer(0.2).timeout


#Spawns bombs in a square pattern - direction is based on whether it's in the middle or not
func queue_special_bomb_string():
	var x = Config.arena_width / 2.0
	var y = Config.arena_height / 2.0
	
	var x_to_add = 64 * (1 if rng.randi() % 2 == 0 else -1)
	var y_to_add = 64 * (1 if rng.randi() % 2 == 0 else -1)
	
	for i in range (0,4):
		next_event_pos.append(Vector2(x + (x_to_add * i), y + (y_to_add * i)))


#Spawns bombs in a square pattern - direction is based on whether it's in the middle or not
func spawn_special_bomb_string():
	var spawn_positions = next_event_pos.duplicate()
	
	for index in range(0, spawn_positions.size()):
		spawn_event_at_pos([spawn_positions[index]], SCENE_BOMB, $Bombs)
		await get_tree().create_timer(0.2).timeout


#Spawns gravity in the outer ring, or the inner ring - randomly
func queue_special_zero_gravity():
	var x = Config.arena_width / 2.0
	var y = Config.arena_height / 2.0
	var to_add = 140
	
	next_event_pos.append(Vector2(x, y - to_add))
	next_event_pos.append(Vector2(x, y + to_add))
	next_event_pos.append(Vector2(x + to_add, y - to_add))
	next_event_pos.append(Vector2(x + to_add, y + to_add))
	next_event_pos.append(Vector2(x + to_add, y))
	next_event_pos.append(Vector2(x - to_add, y + to_add))
	next_event_pos.append(Vector2(x - to_add, y))
	next_event_pos.append(Vector2(x - to_add, y - to_add))
	next_event_pos.append(Vector2(x, y))


func spawn_special_zero_gravity():
	var spawn_positions = next_event_pos.duplicate()
	
	for index in range(0, spawn_positions.size()):
		spawn_event_at_pos([spawn_positions[index]], SCENE_GRAVITY_FIELD, $GravityFields)


#Spawns pull fields under each cannon to try to pull players towards them
func queue_special_cannon_pull():
	for cannon_pos in coordinates_for_cannons:
		next_event_pos.append(cannon_pos)


#Spawns pull fields under each cannon to try to pull players towards them
func spawn_special_cannon_pull():
	var spawn_positions = next_event_pos.duplicate()
	
	for index in range(0, spawn_positions.size()):
		spawn_event_at_pos([spawn_positions[index]], SCENE_PULL_FIELD, $PullFields)


func setup_arena_walls():
	create_wall($WallLeft, -Config.wall_width / 2.0, Config.arena_height / 2.0, Config.wall_width, Config.arena_height)
	create_wall($WallRight, Config.arena_width + Config.wall_width / 2.0, Config.arena_height / 2.0, Config.wall_width, Config.arena_height)
	create_wall($WallTop, Config.arena_width / 2.0, -Config.wall_width / 2.0, Config.arena_width, Config.wall_width)
	create_wall($WallBottom, Config.arena_width / 2.0, Config.arena_height + Config.wall_width / 2.0, Config.arena_width, Config.wall_width)


func setup_players():
	var center_pos = Vector2(Config.arena_width / 2.0, Config.arena_height / 2.0)
	var player_size = SCENE_PLAYER.instantiate().get_node("Sprite2D").texture.get_size()
	
	var spot_index = 0
	
	for i in GameManager.players:
		var current_player = SCENE_PLAYER.instantiate()
		
		#Set the player objects name as the peer id so we can use this for authority reasons
		current_player.name = str(GameManager.players[i].id)
		current_player.get_node("Name").text = str(GameManager.players[i].name)
		
		match spot_index:
			0: current_player.position = center_pos + Vector2(-player_size.x, 0)
			1: current_player.position = center_pos + Vector2(-player_size.x, -player_size.y)
			2: current_player.position = center_pos + Vector2(0, -player_size.y)
			3: current_player.position = center_pos + Vector2(player_size.x, -player_size.y)
			4: current_player.position = center_pos + Vector2(player_size.x, 0)
			5: current_player.position = center_pos + Vector2(player_size.x, player_size.y)
			6: current_player.position = center_pos + Vector2(0, player_size.y)
			7: current_player.position = center_pos + Vector2(-player_size.x, player_size.y)
		
		$Players.add_child(current_player)
		
		spot_index += 1


func create_wall(wall_node: Node, posx: float, posy: float, scalex: float, scaley: float):
	wall_node.position.x = posx
	wall_node.position.y = posy
	
	wall_node.scale.x = scalex
	wall_node.scale.y = scaley


#Think of breaking the arena into a ninepatchrect; then putting cannons everwhere but the middle
func setup_cannon_spots():
	var cannon_sprite_width = SCENE_CANNON.instantiate().get_node("Sprite2D").texture.get_size().x
	
	#Get the distance apart from each cannon, for each axis
	var available_width = Config.arena_width - (distance_from_walls * 2)
	var available_height = Config.arena_height - (distance_from_walls * 2)
	
	#The empty space besides what the cannons would take up, using their sprite size 
	var empty_non_cannon_width = available_width - (cannon_sprite_width * 3)
	var empty_non_cannon_height = available_height - (cannon_sprite_width * 3)

	#Find the distance between each cannon, assuming 8 cannons in the outer ring
	#We are measuring the adjacent empty spots (x's); o's are cannons, x's are empty: (o x o x o )
	var width_between = empty_non_cannon_width / 2.0
	var height_between = empty_non_cannon_height / 2.0

	#Start populating the cannons
	var x_coord = distance_from_walls
	var y_coord = distance_from_walls
	
	for row in range(1, 4):
		x_coord = distance_from_walls
		
		for col in range(1, 4):
			#Skip the middle square
			if row == 2 and col == 2:
				#Move the pointer by the cannon sprite
				x_coord += width_between + cannon_sprite_width
				continue
			
			coordinates_for_cannons.append(Vector2(x_coord, y_coord))
			
			#Move the pointer by the cannon sprite
			x_coord += width_between + cannon_sprite_width
		
		#Move the pointer by the cannon sprite
		y_coord += height_between + cannon_sprite_width
	
	#Duplicate cannon spots so we can see where they originally were, and which are left to take
	available_coordinates_for_cannons = coordinates_for_cannons.duplicate()


func _on_players_child_exiting_tree(node):
	if $Players.get_child_count() == 1:
		$SpawnerTimer.stop()
		
		var win_text = SCENE_WIN_TEXT.instantiate()
		var player_name = GameManager.players[int(str(node.name))].name
		
		win_text.change_name(player_name)
		win_text.position = Vector2(Config.arena_width / 2.0, Config.arena_height / 2.0)
		
		win_text.get_lobby_button().pressed.connect(_on_lobby_button_pressed)
		win_text.get_exit_button().pressed.connect(_on_exit_button_pressed)
		
		add_child(win_text)
		

func _on_lobby_button_pressed():
	multiplayer_manager.load_lobby()

	queue_free()
	
	
func _on_exit_button_pressed():
	await multiplayer_manager.start_fade()
	
	multiplayer_manager.show()
	multiplayer_manager.player_left_lobby.rpc()

	queue_free()


func play_sound(sound_type: Enum.SOUND):
	match sound_type:
		Enum.SOUND.BEAM: $AudioBeam.play()
		Enum.SOUND.BOMB: $AudioBomb.play()
		Enum.SOUND.SHOT: $AudioShot.play()
		Enum.SOUND.DEATH: $AudioDeath.play()
