extends Node2D

@export var player_list: Node


func _ready():
	pass


func _process(delta):
	for child in get_children():
		#TODO: Need to do this inside the cannon to see which player is closest
		var player = player_list.get_child(0)
		child.look_at(player.position)
		child.set_target(player)
