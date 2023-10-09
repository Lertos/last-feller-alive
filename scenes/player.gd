extends CharacterBody2D

enum DIRECTION {LEFT, RIGHT}

var dir: DIRECTION = DIRECTION.RIGHT
var is_dashing: bool = false
var is_being_pulled: bool = false
var is_dead: bool = false
var is_hurt: bool = false
var is_slowed: bool = false

@export var pull_speed = 300
@export var normal_speed = 500
@export var dashing_speed = 900

var speed
var pull_point: Vector2
var health: float = 100.0


func _ready():
	#Set the authority so we can do checks on if this is the local players object
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	$AnimationPlayer.play("idle")
	
	#setup the proper skin chosen in the lobby for this player object
	var skin_index = GameManager.players[self.name.to_int()].skin_index
	$Sprite2D.texture = GameManager.skins[skin_index]
	
	#Set the default speed so we can update it later
	speed = normal_speed


func get_input():
	#If this player object is NOT our player, then simply return
	if $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
		
	if is_dashing or is_dead:
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play("idle")
		return
	
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_just_pressed("dash"):
		is_dashing = true
		speed = dashing_speed
		
		velocity = input_direction * speed
		
		$AnimationPlayer.play("dash")
		return
	
	velocity = input_direction * speed
	
	if input_direction == Vector2.ZERO:
		$AnimationPlayer.play("idle")
	else:
		if input_direction.x > 0 and dir == DIRECTION.LEFT:
			$Sprite2D.scale.x *= -1
			dir = DIRECTION.RIGHT
		elif input_direction.x < 0 and dir == DIRECTION.RIGHT:
			$Sprite2D.scale.x *= -1
			dir = DIRECTION.LEFT
		if not is_hurt:
			$AnimationPlayer.play("run")


func add_health(hp: int):
	health += hp
	$HPBar.value = min(health, 100.0)

	if health <= 0:
		is_dead = true
		$AnimationPlayer.play("death")
		return
	else:
		is_hurt = true
		$AnimationPlayer.play("hurt")
		return


func reset_state():
	speed = normal_speed
	
	if is_slowed:
		speed /= 2

	is_dashing = false
	is_hurt = false


func set_player_slowed(val: bool):
	#If both values are the same, nothing needs to change so just return
	if is_slowed == val:
		return
	
	#Now we know both values are different 
	if is_slowed:
		is_slowed = false
		speed *= 2
	else:
		is_slowed = true
		speed /= 2


func set_pull_point(pos: Vector2):
	pull_point = pos
	is_being_pulled = true


func remove_pull():
	is_being_pulled = false


func _physics_process(delta):
	if is_dead:
		return
		
	get_input()
	
	if not is_dashing and is_being_pulled:
		if abs(position.x - pull_point.x) > 5 or abs(position.y - pull_point.y) > 5:
			velocity += global_position.direction_to(pull_point) * pull_speed
	
	move_and_slide()


func player_death():
	queue_free()
