extends Node2D

var skin_index


func _ready():
	$AnimationPlayer.play("idle")

	$Name.text = GameManager.players[multiplayer.get_unique_id()].name
	
	#Get the current skin_index
	skin_index = GameManager.players[multiplayer.get_unique_id()].skin_index

	change_skin()


func _on_previous_pressed():
	if skin_index == 0:
		skin_index = GameManager.skins.size() - 1
	else:
		skin_index -= 1
		
	change_skin()


func _on_next_pressed():
	if skin_index == GameManager.skins.size() - 1:
		skin_index = 0
	else:
		skin_index += 1
		
	change_skin()


func change_skin():
	GameManager.players[multiplayer.get_unique_id()].skin_index = skin_index

	$Sprite2D.texture = GameManager.skins[skin_index][0]
	$HB/SkinName.text = GameManager.skins[skin_index][1]

	get_tree().root.get_node("MultiplayerManager").update_player_skin.rpc(skin_index)
