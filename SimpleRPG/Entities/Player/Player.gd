extends KinematicBody2D

# Player stats
var health = 100
var health_max = 100
var health_regeneration = 1
var mana = 100
var mana_max = 100
var mana_regeneration = 2

signal player_stats_changed

# Player Movement Speed
export var speed = 75

var last_direction = Vector2(0, 1)
var attack_playing = false

# Attack variables
var attack_cooldown_time = 1000
var next_attack_time = 0
var attack_damage = 30

func _ready():
	emit_signal("player_stats_changed", self)

func _process(delta):
	# Regenerates mana
	var new_mana = min(mana + mana_regeneration * delta, mana_max)
	if new_mana != mana:
		mana = new_mana
		emit_signal("player_stats_changed", self)
	
	# Regenerates Health
	var new_health = min(health + health_regeneration * delta, health_max)
	if new_health != health:
		health = new_health
		emit_signal("player_stats_changed", self)

func _physics_process(delta):
	# Get Player input
	var direction: Vector2
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# If input is digital, normalize it for diagonal movement
	if abs(direction.x) == 1 and abs(direction.y) == 1:
		direction = direction.normalized()
		
	# Apply Movement
	var movement = speed * direction * delta
	if attack_playing:
		movement = 0.3 * movement
	move_and_collide(movement)
	
	# Animate player based on direction
	if  not attack_playing:
		_animates_player(direction)
	
	# Turn RayCast2D toward movement direction
	if direction != Vector2.ZERO:
		$RayCast2D.cast_to = direction.normalized() * 9

func _animates_player(direction: Vector2):
	if direction != Vector2.ZERO:
		# Gradually update last_direction to counteract bounce of analog stick
		last_direction = 0.5 * last_direction + 0.5 * direction
		
		# Choose walk animation based on movement direction
		var animation = get_animation_direction(last_direction) + "_walk"
		
		# Play walk animation
		$Sprite.frames.set_animation_speed(animation, 2 + 8 * direction.length())
		$Sprite.play(animation)
	else:
		# Choose walk animation based on movement direction
		var animation = get_animation_direction(last_direction) + "_idle"
		
		# Play idle animation
		$Sprite.play(animation)

func get_animation_direction(direction: Vector2):
	var norm_direction = direction.normalized()
	if norm_direction.y >= 0.707:
		return "down"
	elif norm_direction.y <= -0.707:
		return "up"
	elif norm_direction.x <= -0.707:
		return "left"
	elif norm_direction.x >= 0.707:
		return "right"
	else:
		return "down"

func _input(event):
	if event.is_action_pressed("attack"):
		# Check if player can attack
		var now = OS.get_ticks_msec()
		
		if now >= next_attack_time:
			# What's the target?
			var target = $RayCast2D.get_collider()
			
			if target != null:
				if target.name.find("Skeleton") >= 0:
					# Skeleton hit!
					target.hit(attack_damage)
			
			# Play attack animation
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_attack"
			$Sprite.play(animation)
			
			# Add cooldown time to current time
			next_attack_time = now + attack_cooldown_time
	elif event.is_action_pressed("fireball"):
		if mana >= 25:
			mana = mana - 25
			emit_signal("player_stats_changed", self)
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_fireball"
			$Sprite.play(animation)

func _on_Sprite_animation_finished():
	attack_playing = false
