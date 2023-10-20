extends Node2D

enum DIFFICULTY {EASY, MEDIUM, HARD}
enum EVENT_TYPE {BEAM, BOMB, GRAVITY_FIELD, PULL_FIELD}
enum SPECIAL_EVENT_TYPE {MULTI_BEAM, BOMB_STRING, ZERO_GRAVITY, CANNON_PULL}

#Objects to spawn
const SCENE_PLAYER = preload("res://scenes/player.tscn")
const SCENE_WALL = preload("res://scenes/wall.tscn")
const SCENE_BEAM = preload("res://scenes/beam.tscn")
const SCENE_BOMB = preload("res://scenes/bomb.tscn")
const SCENE_CANNON = preload("res://scenes/cannon.tscn")
const SCENE_GRAVITY_FIELD = preload("res://scenes/gravity_field.tscn")
const SCENE_PULL_FIELD = preload("res://scenes/pull_field.tscn")

var coordinates_for_cannons: Array[Vector2] = []
var available_coordinates_for_cannons: Array[Vector2] = []

#Used to dynamically grab the correct settings for the difficulty
var difficulty_settings = {
	DIFFICULTY.EASY: {
		"initial_spawn_time": 2.0,
		"time_decrease_per_cannon": 0.5,
		"events_before_cannon": 6,
		"special_events_per_cannon": 1
	}
	#TODO: Fill this out for other difficulties
}

#Arena configuration variables
var chosen_difficulty: DIFFICULTY = DIFFICULTY.EASY
var distance_from_walls = Config.wall_width

#Variables to keep track of game state
var total_events_since_cannon: int = 0
var special_events_since_cannon: int = 0

var rng = RandomNumberGenerator.new()


func _ready():
	#Set the initial time for spawning to start
	$SpawnerTimer.wait_time = difficulty_settings[chosen_difficulty]["initial_spawn_time"]
	$SpawnerTimer.timeout.connect(spawn_object)
	
	setup_arena_walls()
	setup_players()
	setup_cannon_spots()
	
	$SpawnerTimer.start()


func spawn_object():
	#If the counter is at 0, spawn a cannon. This is so we can keep count and just reset easily
	if total_events_since_cannon == 0:
		spawn_cannon()
		
		total_events_since_cannon += 1
		return
	
	#Figure out if it's a special event or normal event, then spawn it
	var is_special_event: bool = (rng.randi() % 2 == 0)
	
	if special_events_since_cannon >= difficulty_settings[chosen_difficulty]["special_events_per_cannon"]:
		is_special_event = false
	
	#If special event
	if is_special_event:
		match rng.randi_range(0, SPECIAL_EVENT_TYPE.size() - 1):
			SPECIAL_EVENT_TYPE.MULTI_BEAM:
				spawn_special_multi_beam()
			SPECIAL_EVENT_TYPE.BOMB_STRING:
				spawn_special_bomb_string()
			SPECIAL_EVENT_TYPE.ZERO_GRAVITY:
				spawn_special_zero_gravity()
			SPECIAL_EVENT_TYPE.CANNON_PULL:
				spawn_special_cannon_pull()
				
		special_events_since_cannon += 1
	#If normal event
	else:
		match rng.randi_range(0, EVENT_TYPE.size() - 1):
			EVENT_TYPE.BEAM:
				spawn_event_at_random(distance_from_walls * 2, SCENE_BEAM, $Beams)
			EVENT_TYPE.BOMB:
				spawn_event_at_random(distance_from_walls * 2, SCENE_BOMB, $Bombs)
			EVENT_TYPE.GRAVITY_FIELD:
				spawn_event_at_random(distance_from_walls * 2, SCENE_GRAVITY_FIELD, $GravityFields)
			EVENT_TYPE.PULL_FIELD:
				spawn_event_at_random(distance_from_walls * 2, SCENE_PULL_FIELD, $PullFields)

	#Increase the counters
	if total_events_since_cannon > difficulty_settings[chosen_difficulty]["events_before_cannon"]:
		total_events_since_cannon = 0
	else:
		total_events_since_cannon += 1


func spawn_cannon():
	var new_cannon = SCENE_CANNON.instantiate()
	var rand_index = rng.randi_range(0, available_coordinates_for_cannons.size() - 1)
	var new_spot: Vector2 = available_coordinates_for_cannons[rand_index]
	
	$Cannons.add_child(new_cannon)
	
	new_cannon.position = new_spot
	
	available_coordinates_for_cannons.remove_at(rand_index)
	
	$SpawnerTimer.stop()
	$SpawnerTimer.wait_time = max($SpawnerTimer.wait_time - difficulty_settings[chosen_difficulty]["time_decrease_per_cannon"], 1.0)
	$SpawnerTimer.start()


func spawn_event_at_random(padding: int, event_scene: PackedScene, parent_node: Node):
	var left_top_corner = Vector2(padding, padding)
	var bottom_right_corner = Vector2(Config.arena_width - padding, Config.arena_height - padding)
	
	var x = rng.randi_range(left_top_corner.x, bottom_right_corner.x)
	var y = rng.randi_range(left_top_corner.y, bottom_right_corner.y)
	
	var new_event = event_scene.instantiate()

	parent_node.add_child(new_event)
	
	new_event.position = Vector2(x, y)
	

func spawn_event_at_pos(pos: Vector2, event_scene: PackedScene, parent_node: Node):
	var new_event = event_scene.instantiate()

	parent_node.add_child(new_event)
	
	new_event.position = pos


#Spawns multiple beams back to back with a slight time inbetween
func spawn_special_multi_beam():
	for i in range (0,4):
		spawn_event_at_random(distance_from_walls * 2, SCENE_BEAM, $Beams)
		await get_tree().create_timer(0.2).timeout
	

#Spawns bombs in a square pattern - direction is based on whether it's in the middle or not
func spawn_special_bomb_string():
	for i in range (0,4):
		spawn_event_at_random(distance_from_walls * 2, SCENE_BOMB, $Bombs)
		await get_tree().create_timer(0.4).timeout
	

#Spawns gravity in the outer ring, or the inner ring - randomly
func spawn_special_zero_gravity():
	pass
	

#Spawns pull fields under each cannon to try to pull players towards them
func spawn_special_cannon_pull():
	pass
	

func setup_arena_walls():
	create_wall($WallLeft, -Config.wall_width / 2, Config.arena_height / 2, Config.wall_width, Config.arena_height)
	create_wall($WallRight, Config.arena_width + Config.wall_width / 2, Config.arena_height / 2, Config.wall_width, Config.arena_height)
	create_wall($WallTop, Config.arena_width / 2, -Config.wall_width / 2, Config.arena_width, Config.wall_width)
	create_wall($WallBottom, Config.arena_width / 2, Config.arena_height + Config.wall_width / 2, Config.arena_width, Config.wall_width)


func setup_players():
	var center_pos = Vector2(Config.arena_width / 2, Config.arena_height / 2)
	var player_size = SCENE_PLAYER.instantiate().get_node("Sprite2D").texture.get_size()
	
	var spot_index = 0
	
	for i in GameManager.players:
		var current_player = SCENE_PLAYER.instantiate()
		
		#Set the player objects name as the peer id so we can use this for authority reasons
		current_player.name = str(GameManager.players[i].id)
		current_player.get_node("Name").text = str(GameManager.players[i].name)
		
		$Players.add_child(current_player)
		
		match spot_index:
			0:
				current_player.position = center_pos + Vector2(-player_size.x, 0)
			1:
				current_player.position = center_pos + Vector2(-player_size.x, -player_size.y)
			2:
				current_player.position = center_pos + Vector2(0, -player_size.y)
			3:
				current_player.position = center_pos + Vector2(player_size.x, -player_size.y)
			4:
				current_player.position = center_pos + Vector2(player_size.x, 0)
			5:
				current_player.position = center_pos + Vector2(player_size.x, player_size.y)
			6:
				current_player.position = center_pos + Vector2(0, player_size.y)
			7:
				current_player.position = center_pos + Vector2(-player_size.x, player_size.y)
		
		spot_index += 1


func create_wall(wall_node: Node, posx: int, posy: int, scalex: int, scaley: int):
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
	var width_between = empty_non_cannon_width / 2
	var height_between = empty_non_cannon_height / 2

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
