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
