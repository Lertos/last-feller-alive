extends Node2D


func explosion_done():
	get_parent().queue_free()
