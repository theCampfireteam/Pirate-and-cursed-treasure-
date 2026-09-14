# Player Controller for Godot 4
# Handles player input and integrates with attack system
extends CharacterBody2D

class_name Player

@export var speed: float = 200.0
@export var max_health: int = 100

var current_health: int
var attack_system: AttackSystem
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D

signal health_changed(new_health: int, max_health: int)
signal died()

func _ready():
	current_health = max_health
	
	# Create and attach attack system
	attack_system = AttackSystem.new()
	add_child(attack_system)
	set_meta("animated_sprite", $AnimatedSprite2D if has_node("AnimatedSprite2D") else null)
	
	# Connect attack system signals
	attack_system.attack_hit.connect(_on_attack_hit)
	
	# Setup collision detection
	collision_layer = 1
	collision_mask = 2 | 4  # Detect enemies and obstacles

func _process(_delta):
	handle_input()
	handle_animation()

func _physics_process(delta):
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector.normalized() * speed
	move_and_slide()

func handle_input():
	# Light Attack - Left Mouse/X button
	if Input.is_action_just_pressed("ui_accept"):  # Space or Gamepad A
		var direction = get_attack_direction()
		attack_system.perform_attack("slash", self, direction)
	
	# Power Attack - Right Mouse/Y button
	if Input.is_action_just_pressed("ui_select"):  # Shift or Gamepad Y
		var direction = get_attack_direction()
		attack_system.perform_attack("power_attack", self, direction)
	
	# Cannon/Special - Gamepad X
	if Input.is_action_just_pressed("ui_focus_next"):
		var direction = get_attack_direction()
		attack_system.perform_attack("cannon", self, direction)

func get_attack_direction() -> Vector2:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector != Vector2.ZERO:
		return input_vector.normalized()
	return Vector2.RIGHT  # Default to right

func handle_animation():
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		
		if attack_system.is_attacking:
			# Animation handled by attack system
			pass
		elif input_vector != Vector2.ZERO:
			sprite.play("walk")
			if input_vector.x < 0:
				sprite.flip_h = true
			elif input_vector.x > 0:
				sprite.flip_h = false
		else:
			sprite.play("idle")

func take_damage(damage: int):
	current_health -= damage
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func apply_knockback(force: Vector2):
	velocity = force
	move_and_slide()

func die():
	died.emit()
	queue_free()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
