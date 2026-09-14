# Progressive Combo Attack System for Godot 4
# Each button press = next attack in sequence. Air attack when player is airborne.
extends Node

class_name ProgressiveComboSystem

# Combo state
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_reset_time: float = 2.0  # Reset combo if no attack for 2 seconds
var is_player_airborne: bool = false

# Damage values - each attack is 1 million damage
var combo_damage: int = 1000000

# Attack patterns in sequence
var attack_sequence: Array = [
	"attack_1",
	"attack_2", 
	"attack_3",
	"ground_finish"  # 4th hit finishes combo, resets to start
]

var air_attack: String = "air_strike"

signal combo_step(step: int, attack_name: String)
signal combo_reset()
signal air_strike_performed()
signal damage_dealt(damage: int, target: Node)

func _ready():
	pass

func _process(delta):
	# Countdown combo timer
	if combo_timer > 0:
		combo_timer -= delta
	elif combo_count > 0:
		# Reset combo if timer expired
		combo_count = 0
		combo_timer = 0
		combo_reset.emit()

func perform_attack(attacker: Node, direction: Vector2) -> bool:
	"""Perform the next attack in combo sequence"""
	
	# Check if player is airborne
	if attacker.is_in_group("player") or attacker.has_method("is_on_floor"):
		is_player_airborne = not attacker.is_on_floor() if attacker.has_method("is_on_floor") else false
	
	# If airborne, perform air strike instead
	if is_player_airborne:
		return perform_air_strike(attacker, direction)
	
	# Get current attack in sequence
	var current_attack = attack_sequence[combo_count]
	
	# Perform the attack
	_execute_attack(attacker, current_attack, direction)
	
	# Emit signal
	combo_step.emit(combo_count + 1, current_attack)
	
	# Move to next combo step
	combo_count += 1
	
	# Reset combo after 4 hits
	if combo_count >= attack_sequence.size():
		combo_count = 0
		combo_reset.emit()
	
	# Reset timer for next attack window
	combo_timer = combo_reset_time
	
	return true

func perform_air_strike(attacker: Node, direction: Vector2) -> bool:
	"""Perform air strike (1 million damage) when player is in air"""
	
	_execute_attack(attacker, air_attack, direction)
	air_strike_performed.emit()
	
	# Reset combo when air strike is used
	combo_count = 0
	combo_timer = 0
	combo_reset.emit()
	
	return true

func _execute_attack(attacker: Node, attack_name: String, direction: Vector2):
	"""Execute the actual attack with 1 million damage"""
	
	var damage = combo_damage
	var range_distance: float
	var knockback: float
	
	# Define attack properties
	match attack_name:
		"attack_1":
			range_distance = 60.0
			knockback = 150.0
			print("⚔️ ATTACK 1 - 1,000,000 DAMAGE!")
		
		"attack_2":
			range_distance = 70.0
			knockback = 200.0
			print("⚔️ ATTACK 2 - 1,000,000 DAMAGE!")
		
		"attack_3":
			range_distance = 80.0
			knockback = 250.0
			print("⚔️ ATTACK 3 - 1,000,000 DAMAGE!")
		
		"ground_finish":
			range_distance = 100.0
			knockback = 400.0
			print("💥 GROUND FINISH - 1,000,000 DAMAGE! COMBO RESETS!")
		
		"air_strike":
			range_distance = 120.0
			knockback = 500.0
			print("🌤️ AIR STRIKE - 1,000,000 DAMAGE! DEVASTATING!")
		
		_:
			range_distance = 60.0
			knockback = 100.0
	
	# Get all enemies in range
	var targets = _get_targets_in_range(attacker, range_distance)
	
	# Deal damage to each target
	for target in targets:
		if target == attacker:
			continue
		
		if target.has_method("take_damage"):
			target.take_damage(damage)
			damage_dealt.emit(damage, target)
		
		if target.has_method("apply_knockback"):
			target.apply_knockback(direction * knockback)
	
	# Play animation if exists
	if attacker.has_node("AnimatedSprite2D"):
		var sprite = attacker.get_node("AnimatedSprite2D")
		sprite.play(attack_name)

func _get_targets_in_range(attacker: Node, range_distance: float) -> Array:
	"""Get all enemies within attack range"""
	var targets = []
	var space_state = attacker.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = range_distance
	query.shape = circle_shape
	query.transform = attacker.global_transform
	query.collision_mask = 2  # Enemies on layer 2
	
	var results = space_state.intersect_shape(query)
	for result in results:
		if result.collider != attacker:
			targets.append(result.collider)
	
	return targets

func get_combo_count() -> int:
	"""Get current combo count (0-3, then resets)"""
	return combo_count

func get_combo_progress() -> String:
	"""Get visual representation of combo progress"""
	var progress = ""
	for i in range(4):
		if i < combo_count:
			progress += "●"  # Filled circle = completed
		else:
			progress += "○"  # Empty circle = next
	return progress

func reset_combo_manual():
	"""Manually reset combo"""
	combo_count = 0
	combo_timer = 0
	combo_reset.emit()

func is_combo_active() -> bool:
	"""Check if combo is currently active"""
	return combo_timer > 0 and combo_count > 0
