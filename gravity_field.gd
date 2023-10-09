extends Node2D


func _ready():
	var tween = $BG.create_tween().set_loops()
	tween.tween_property($BG, "rotation", TAU, 3).as_relative()
	
	var tween3 = $FG.create_tween().set_loops()
	tween3.tween_property($FG, "rotation", TAU, 1).as_relative()

	var tween2 = self.create_tween().set_loops()
	tween2.tween_property(self, "scale", Vector2(6,6), 1.5)
	tween2.tween_property(self, "scale", Vector2(2,2), 1.5)
	
	var tween5 = self.create_tween().set_loops()
	tween5.tween_property(self, "modulate", Color.html("#ffffff92"), 1.5)
	tween5.tween_property(self, "modulate", Color.html("#ffffff"), 1.5)
