# Attack System for Godot 4
# Main controller for player and enemy attacks
extends Node

class_name AttackSystem

# Attack data
var attacks: Dictionary = {}
var combo_counter: int = 0
var is_attacking: bool = false
var attack_cooldown: float = 0.0

signal attack_started(attack_name: String)
signal attack_ended()
signal combo_updated(combo_count: int)
signal attack_hit(damage: int, target: Node)

func _ready():
	_initialize_attacks()

func _process(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta

func _initialize_attacks():
	# Basic slash attack
	attacks["slash"] = {
		"damage": 15,
		"cooldown": 0.5,
		"animation": "slash",
		"range": 50,
		"knockback": 100,
		"combo_window": 0.6
	}
	
	# Power attack
	attacks["power_attack"] = {
		"damage": 30,
		"cooldown": 1.2,
		"animation": "power_attack",
		"range": 60,
		"knockback": 200,
		"combo_window": 0.8,
		"requires_combo": 2
	}
	
	# Piercing attack
	attacks["pierce"] = {
		"damage": 20,
		"cooldown": 0.7,
		"animation": "pierce",
		"range": 80,
		"knockback": 50,
		"penetrating": true
	}
	
	# Cannon attack (special)
	attacks["cannon"] = {
		"damage": 50,
		"cooldown": 3.0,
		"animation": "cannon",
		"range": 300,
		"knockback": 300,
		"projectile": true,
		"aoe": true,
		"aoe_radius": 100
	}

func perform_attack(attack_name: String, attacker: Node, direction: Vector2):
	if not attacks.has(attack_name):
		push_error("Attack not found: " + attack_name)
		return false
	
	if is_attacking or attack_cooldown > 0:
		return false
	
	var attack_data = attacks[attack_name]
	
	# Check combo requirements
	if attack_data.has("requires_combo") and combo_counter < attack_data["requires_combo"]:
		return false
	
	is_attacking = true
	attack_started.emit(attack_name)
	
	# Play animation if attacker has AnimatedSprite
	if attacker.has_meta("animated_sprite"):
		var sprite = attacker.get_meta("animated_sprite")
		sprite.play(attack_data["animation"])
	
	# Deal damage to targets in range
	_deal_damage(attacker, attack_data, direction)
	
	# Set cooldown
	attack_cooldown = attack_data["cooldown"]
	
	# Reset combo if not in combo window
	if not attack_data.has("combo_window"):
		combo_counter = 0
	else:
		combo_counter += 1
		combo_updated.emit(combo_counter)
	
	is_attacking = false
	attack_ended.emit()
	
	return true

func _deal_damage(attacker: Node, attack_data: Dictionary, direction: Vector2):
	var damage = attack_data["damage"]
	var range_distance = attack_data["range"]
	var knockback = attack_data["knockback"]
	
	# Get all potential targets in range
	var space_state = attacker.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Use a circle shape for range detection
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = range_distance
	query.shape = circle_shape
	query.transform = attacker.global_transform
	
	# Set collision mask (adjust based on your game)
	query.collision_mask = 2  # Enemies on layer 2
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var target = result.collider
		
		# Make sure we don't hit ourselves
		if target == attacker:
			continue
		
		# Apply damage
		if target.has_method("take_damage"):
			target.take_damage(damage)
			attack_hit.emit(damage, target)
		
		# Apply knockback
		if target.has_method("apply_knockback"):
			target.apply_knockback(direction * knockback)
		elif target.has_property("velocity"):
			target.velocity += direction * knockback
	
	# Handle AOE attacks
	if attack_data.has("aoe") and attack_data["aoe"]:
		_handle_aoe(attacker, attack_data, damage, knockback)

func _handle_aoe(attacker: Node, attack_data: Dictionary, damage: int, knockback: float):
	var aoe_radius = attack_data.get("aoe_radius", 100)
	var space_state = attacker.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = aoe_radius
	query.shape = circle_shape
	query.transform = attacker.global_transform
	query.collision_mask = 2
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var target = result.collider
		if target == attacker:
			continue
		
		if target.has_method("take_damage"):
			target.take_damage(int(damage * 0.75))  # AOE does 75% damage

func reset_combo():
	combo_counter = 0
	combo_updated.emit(0)

func can_attack(attack_name: String = "") -> bool:
	if is_attacking or attack_cooldown > 0:
		return false
	if attack_name != "" and attacks.has(attack_name):
		var attack_data = attacks[attack_name]
		if attack_data.has("requires_combo") and combo_counter < attack_data["requires_combo"]:
			return false
	return true

func get_cooldown_percent(attack_name: String = "") -> float:
	if attack_name == "":
		return 1.0 - (attack_cooldown / 1.0)  # Generic cooldown
	if attacks.has(attack_name):
		var cooldown = attacks[attack_name]["cooldown"]
		return 1.0 - (attack_cooldown / cooldown)
	return 1.0
