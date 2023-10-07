extends Node2D

const SCENE_WALL = preload("res://scenes/wall.tscn")
const SCENE_PLAYER = preload("res://scenes/player.tscn")

var min_distance_from_corners = Config.wall_width * 2
var rng = RandomNumberGenerator.new()
var open_wall_spots = {
	"left": [],
	"right": [],
	"top": [],
	"bottom": []
}

func _ready():
	setup_arena_walls()
	setup_players()

func setup_arena_walls():
	create_wall(
		$WallLeft, 
		-Config.wall_width / 2, 
		Config.arena_height / 2, 
		Config.wall_width, 
		Config.arena_height
	)
	create_wall(
		$WallRight, 
		Config.arena_width + Config.wall_width / 2, 
		Config.arena_height / 2, 
		Config.wall_width, 
		Config.arena_height
	)
	create_wall(
		$WallTop, 
		Config.arena_width / 2, 
		-Config.wall_width / 2, 
		Config.arena_width, 
		Config.wall_width
	)
	create_wall(
		$WallBottom, 
		Config.arena_width / 2, 
		Config.arena_height + Config.wall_width / 2, 
		Config.arena_width, 
		Config.wall_width
	)
	
	fill_open_wall_spots()
	
	for i in range(0,30):
		create_moving_wall()


func setup_players():
	var center_pos = Vector2(Config.arena_width / 2, Config.arena_height / 2)
	var player_size = SCENE_PLAYER.instantiate().get_node("Sprite2D").texture.get_size()
	
	var spot_index = 0
	
	for i in GameManager.players:
		var current_player = SCENE_PLAYER.instantiate()
		
		#Set the player objects name as the peer id so we can use this for authority reasons
		current_player.name = str(GameManager.players[i].id)
		
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



func fill_open_wall_spots():
	var vertical_spots = (Config.arena_height - min_distance_from_corners * 2) / Config.wall_width
	var horizontal_spots = (Config.arena_width - min_distance_from_corners * 2) / Config.wall_width
	
	for i in range(0, vertical_spots):
		open_wall_spots["left"].append(i + 1)
		open_wall_spots["right"].append(i + 1)
	
	for i in range(0, horizontal_spots):
		open_wall_spots["top"].append(i + 1)
		open_wall_spots["bottom"].append(i + 1)


func create_wall(wall_node: Node, posx: int, posy: int, scalex: int, scaley: int):
	wall_node.position.x = posx
	wall_node.position.y = posy
	
	wall_node.scale.x = scalex
	wall_node.scale.y = scaley


func create_moving_wall():
	#First get the direction randomly
	var rand_dir = rng.randi_range(0, Enum.GROW_DIRECTION.size() - 1)
	var wall = SCENE_WALL.instantiate()
	
	$Walls.add_child(wall)
	
	wall.position = get_wall_position(rand_dir)
	wall.setup_wall(rand_dir, false)


func get_wall_position(dir: Enum.GROW_DIRECTION):
	#Get random axis
	var is_zero_axis: bool = rng.randi() % 2 == 0
	
	if dir == Enum.GROW_DIRECTION.HORIZONTAL:
		if is_zero_axis:
			return Vector2(0, get_empty_spot("left") * Config.wall_width + min_distance_from_corners)
		else:
			return Vector2(Config.arena_width, get_empty_spot("right") * Config.wall_width + min_distance_from_corners)
	elif dir == Enum.GROW_DIRECTION.VERTICAL:
		if is_zero_axis:
			return Vector2(get_empty_spot("top") * Config.wall_width + min_distance_from_corners, 0)
		else:
			return Vector2(get_empty_spot("bottom") * Config.wall_width + min_distance_from_corners, Config.arena_height)


func get_empty_spot(dir_name):
	if open_wall_spots[dir_name].size() == 0:
		return -1
		
	var rand_index: int = randi_range(0, open_wall_spots[dir_name].size() - 1)
	var value: int = open_wall_spots[dir_name][rand_index]
	
	open_wall_spots[dir_name].remove_at(rand_index)
	return value
