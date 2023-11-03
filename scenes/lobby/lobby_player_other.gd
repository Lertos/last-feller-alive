extends Node2D

var skin_index = 0


func _ready():
	$AnimationPlayer.play("idle")
	change_skin(skin_index)


func change_skin(skin_index):
	$Sprite2D.texture = GameManager.skins[skin_index][0]


func set_player_name(name: String):
	$Name.text = name
