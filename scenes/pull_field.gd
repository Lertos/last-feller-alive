extends Node2D


func _ready():
	$AnimationPlayer.play("spin")


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		body.set_pull_point(position)


func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		body.remove_pull()
