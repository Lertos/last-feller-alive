extends Node2D

var skins = [
	preload("res://assets/player.png"),
	preload("res://assets/player2.png"),
	preload("res://assets/player3.png")
]

var skin_index = 0


func _ready():
	$AnimationPlayer.play("idle")
	change_skin(skin_index)


func change_skin(skin_index):
	$Sprite2D.texture = skins[skin_index]


func set_player_name(name: String):
	$Name.text = name
