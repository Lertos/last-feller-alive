extends Control


func _ready():
	create_tween().tween_property($VB, "modulate", Color.html("#ffffff"), 1.0)


func change_name(winner_name: String):
	$VB/PlayerName.text = winner_name


func get_lobby_button() -> Button:
	return $VB/Buttons/Lobby


func get_exit_button() -> Button:
	return $VB/Buttons/Exit
