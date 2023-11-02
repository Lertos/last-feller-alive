extends CharacterBody2D

enum DIRECTION {LEFT, RIGHT}

var dir: DIRECTION = DIRECTION.RIGHT
var can_dash: bool = true
var is_dashing: bool = false
var is_being_pulled: bool = false
var is_dead: bool = false
var is_hurt: bool = false
var is_slowed: bool = false

@export var pull_speed = 300
@export var normal_speed = 500
@export var dashing_speed = 900
@export var speed: float
@export var health: float = 100.0

var time_between_dashes: float = 2.0
var time_since_dash: float = 0.0

var pull_point: Vector2


func _ready():
	#Set the authority so we can do checks on if this is the local players object
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	$AnimationPlayer.play("idle")
	
	#setup the proper skin chosen in the lobby for this player object
	var skin_index = GameManager.players[self.name.to_int()].skin_index
	$Sprite2D.texture = GameManager.skins[skin_index]
	
	#Set the default speed so we can update it later
	speed = normal_speed


func _process(delta):
	if not can_dash:
		time_since_dash += delta
		
		if time_since_dash >= time_between_dashes:
			$StaminaBar.value = 100.0
			time_since_dash = 0.0
			can_dash = true
		else:
			$StaminaBar.value = (time_since_dash / time_between_dashes) * 100.0


func get_input():
	if is_dashing or is_dead:
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play("idle")
		return
		
	#If this player object is NOT our player, then simply return
	if $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_just_pressed("dash") and can_dash:
		is_dashing = true
		can_dash = false
		speed = dashing_speed
		
		velocity = input_direction * speed
		
		$AnimationPlayer.play("dash")
		
		return
	
	velocity = input_direction * speed
	
	if input_direction == Vector2.ZERO and not is_hurt:
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
	else:
		is_hurt = true
		$AnimationPlayer.play("hurt")


func reset_state():
	$Sprite2D.modulate = Color.html("ffffff")
	
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
