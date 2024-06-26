extends Node2D

@export var time_to_shrink: float = 1.5

@export var min_scale: float = 2.0
@export var max_scale: float = 6.0


func _ready():
	var tween_bg = $BG.create_tween().set_loops()
	tween_bg.tween_property($BG, "rotation", TAU, 0.5).as_relative()
	
	var tween_fg = $FG.create_tween().set_loops()
	tween_fg.tween_property($FG, "rotation", TAU, 1).as_relative()

	var tween_scale = create_tween().set_loops()
	tween_scale.tween_property(self, "scale", Vector2(max_scale, max_scale), time_to_shrink)
	tween_scale.tween_property(self, "scale", Vector2(min_scale, min_scale), time_to_shrink)
	
	var tween_modulate = create_tween().set_loops()
	tween_modulate.tween_property(self, "modulate", Color.html("#ffffff92"), time_to_shrink)
	tween_modulate.tween_property(self, "modulate", Color.html("#ffffff"), time_to_shrink)


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		body.set_player_slowed(true)


func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		body.set_player_slowed(false)


func _on_timer_timeout():
	#Fade before destroying the object
	create_tween().tween_property(self, "modulate", Color.html("#ffffff00"), 1)
	await get_tree().create_timer(1).timeout
	queue_free()
