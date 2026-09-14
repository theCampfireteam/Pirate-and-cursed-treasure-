# Enemy AI for Godot 4
# Simple enemy that patrols and attacks the player
extends CharacterBody2D

class_name Enemy

@export var speed: float = 100.0
@export var max_health: int = 50
@export var detection_range: float = 200.0
@export var attack_range: float = 60.0

var current_health: int
var attack_system: AttackSystem
var player: Player
var state: String = "patrol"  # patrol, chase, attack
var patrol_direction: int = 1
var animated_sprite: AnimatedSprite2D

signal health_changed(new_health: int)
signal died()

func _ready():
	current_health = max_health
	
	# Create and attach attack system
	attack_system = AttackSystem.new()
	add_child(attack_system)
	set_meta("animated_sprite", $AnimatedSprite2D if has_node("AnimatedSprite2D") else null)
	
	# Find player
	player = get_tree().root.get_child(0).find_child("Player", true, false)
	
	# Setup collision detection
	collision_layer = 2  # Enemies on layer 2
	collision_mask = 1 | 2 | 4  # Detect player and obstacles

func _physics_process(delta):
	if not is_instance_valid(player):
		patrol()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Detect player
	if distance_to_player < detection_range:
		state = "chase"
	elif distance_to_player > detection_range * 1.5:
		state = "patrol"
	
	match state:
		"patrol":
			patrol()
		"chase":
			if distance_to_player < attack_range:
				attack()
			else:
				chase()
		"attack":
			attack()
	
	move_and_slide()
	update_animation()

func patrol():
	velocity = Vector2(patrol_direction * speed, 0)
	
	# Change direction randomly or when hitting wall
	if is_on_wall() or randf() < 0.01:
		patrol_direction *= -1

func chase():
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed

func attack():
	velocity = Vector2.ZERO
	
	# Simple attack routine
	if attack_system.can_attack("slash"):
		var direction = (player.global_position - global_position).normalized()
		attack_system.perform_attack("slash", self, direction)

func update_animation():
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		
		if attack_system.is_attacking:
			pass  # Attack animation handled by system
		elif velocity.x != 0:
			sprite.play("walk")
			if velocity.x < 0:
				sprite.flip_h = true
			elif velocity.x > 0:
				sprite.flip_h = false
		else:
			sprite.play("idle")

func take_damage(damage: int):
	current_health -= damage
	health_changed.emit(current_health)
	
	# Flash red when hit
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func apply_knockback(force: Vector2):
	velocity = force

func die():
	died.emit()
	queue_free()
