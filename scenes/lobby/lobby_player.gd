extends Node2D

var skins = [
	preload("res://assets/player.png"),
	preload("res://assets/player2.png"),
	preload("res://assets/player3.png")
]

var skin_index = 0


func _ready():
	$AnimationPlayer.play("idle")
	print(str(GameManager.players))
	$Name.text = GameManager.players[multiplayer.get_unique_id()].name


func _on_previous_pressed():
	if skin_index == 0:
		skin_index = skins.size() - 1
	else:
		skin_index -= 1
		
	change_skin()


func _on_next_pressed():
	if skin_index == skins.size() - 1:
		skin_index = 0
	else:
		skin_index += 1
		
	change_skin()


func change_skin():
	$Sprite2D.texture = skins[skin_index]
	$HB/SkinName.text = "Skin " + str(skin_index + 1)
