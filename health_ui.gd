# Health Display UI for Godot 4
extends CanvasLayer

class_name HealthUI

@onready var player_health_label = Label.new()
@onready var player_health_bar = ProgressBar.new()
@onready var combo_label = Label.new()

var player: Player

func _ready():
	# Find player
	player = get_tree().root.get_child(0).find_child("Player", true, false)
	
	if player:
		# Setup player health bar
		player_health_bar.min_value = 0
		player_health_bar.max_value = player.max_health
		player_health_bar.value = player.current_health
		player_health_bar.size = Vector2(200, 20)
		player_health_bar.position = Vector2(10, 10)
		add_child(player_health_bar)
		
		# Setup player health label
		player_health_label.text = "Health: %d/%d" % [player.current_health, player.max_health]
		player_health_label.position = Vector2(10, 35)
		add_child(player_health_label)
		
		# Setup combo label
		combo_label.text = "Combo: 0"
		combo_label.position = Vector2(10, 60)
		combo_label.add_theme_color_override("font_color", Color.YELLOW)
		add_child(combo_label)
		
		# Connect signals
		player.health_changed.connect(_on_player_health_changed)
		if player.attack_system:
			player.attack_system.combo_updated.connect(_on_combo_updated)

func _on_player_health_changed(new_health: int, max_health: int):
	player_health_bar.max_value = max_health
	player_health_bar.value = new_health
	player_health_label.text = "Health: %d/%d" % [new_health, max_health]

func _on_combo_updated(combo_count: int):
	combo_label.text = "Combo: %d" % combo_count
	if combo_count > 0:
		combo_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		combo_label.add_theme_color_override("font_color", Color.WHITE)
