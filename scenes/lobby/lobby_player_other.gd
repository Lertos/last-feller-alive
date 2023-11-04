extends Node2D

var skin_index = 0


func _ready():
	$AnimationPlayer.play("idle")
	change_skin(skin_index)


func change_skin(new_skin_index):
	$Sprite2D.texture = GameManager.skins[new_skin_index][0]


func set_player_name(player_name: String):
	$Name.text = player_name
