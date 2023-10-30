extends Control


func _ready():
	create_tween().tween_property($VB, "modulate", Color.html("#ffffff"), 1.0)


func change_name(winner_name: String):
	$VB/PlayerName.text = winner_name
