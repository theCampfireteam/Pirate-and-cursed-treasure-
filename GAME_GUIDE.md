
# Pirate and Cursed Treasure - Attack System Guide

## 🎮 How to Play

### Attack Controls
- **Space Bar / Gamepad A** - Light Slash Attack (fast, 15 damage)
- **Shift / Gamepad Y** - Power Attack (slow, 30 damage, requires 2 hit combo)
- **X Key / Gamepad X** - Cannon Attack (special, 50 damage, AOE effect)

### Movement
- **Arrow Keys / WASD** - Move your character
- **Gamepad Analog Stick** - Move your character

---

## 📁 File Structure & What Was Added

```
root/
├── attack_system.gd          ← Core attack logic & damage system
├── player.gd                 ← Player controller with input handling
├── enemy.gd                  ← Enemy AI that patrols and attacks
├── health_ui.gd              ← Health bars and UI display
├── project.godot             ← Project configuration
│
└── scenes/
    ├── main.tscn             ← Main game scene (player + 3 enemies)
    ├── player.tscn           ← Player scene prefab
    └── enemy.tscn            ← Enemy scene prefab
```

### File Descriptions

| File | Purpose |
|------|---------|
| `attack_system.gd` | Manages all attacks, cooldowns, combos, range detection, and damage dealing |
| `player.gd` | Handles player movement, input, and integrates attack system |
| `enemy.gd` | AI for enemies: patrol, chase player, attack when in range |
| `health_ui.gd` | Displays health bars and combo counter |
| `scenes/main.tscn` | Main level with player and 3 enemy spawns |
| `scenes/player.tscn` | Player scene template |
| `scenes/enemy.tscn` | Enemy scene template |

---

## 🔧 How to Attach Attack System to Player (or Enemy)

The attack system is **automatically attached** in the `_ready()` function. Here's how:

### In `player.gd`:
```gdscript
func _ready():
	current_health = max_health
	
	# Create and attach attack system
	attack_system = AttackSystem.new()
	add_child(attack_system)
	set_meta("animated_sprite", $AnimatedSprite2D)
```

### To add it to a new character:
1. Create a new script extending `CharacterBody2D`
2. Add this in `_ready()`:
   ```gdscript
   attack_system = AttackSystem.new()
   add_child(attack_system)
   ```
3. Call attacks with:
   ```gdscript
   attack_system.perform_attack("slash", self, direction)
   ```

---

## 🎬 Animation System

### Current State
**Animations have NOT been created yet.** The system is ready for them, but you'll need to add sprite animations.

### What Animations Are Expected

The attack system calls these animations:
- `idle` - Standing still
- `walk` - Walking/moving
- `slash` - Light attack animation
- `power_attack` - Heavy attack animation
- `pierce` - Piercing attack animation
- `cannon` - Special cannon attack animation

### How to Add Animations

1. **Create sprite sheet images** (you'll need pirate character sprites)
2. **Import into Godot 4**:
   - Right-click sprite image → Import as "Texture2D"
   - Create a `SpriteFrames` resource
   - Add animations (idle, walk, slash, etc.)
3. **Attach to scenes**:
   - In `scenes/player.tscn`, select `AnimatedSprite2D` node
   - Assign the `SpriteFrames` resource
   - Set default animation to "idle"

### Quick Setup (Placeholder)
For testing without art, you can use colored rectangles:
```gdscript
# In player.gd
func handle_animation():
	var sprite = $AnimatedSprite2D
	if attack_system.is_attacking:
		sprite.modulate = Color.RED  # Flash red during attack
	else:
		sprite.modulate = Color.WHITE
```

---

## ⚙️ Attack System Configuration

### Attack Types & Stats

```gdscript
# In attack_system.gd
attacks["slash"] = {
	"damage": 15,
	"cooldown": 0.5,
	"animation": "slash",
	"range": 50,
	"knockback": 100
}

attacks["power_attack"] = {
	"damage": 30,
	"cooldown": 1.2,
	"animation": "power_attack",
	"range": 60,
	"knockback": 200,
	"requires_combo": 2  # Needs 2 hits first
}

attacks["cannon"] = {
	"damage": 50,
	"cooldown": 3.0,
	"animation": "cannon",
	"range": 300,
	"knockback": 300,
	"aoe": true,
	"aoe_radius": 100
}
```

### How to Modify Attacks
Edit values in `attack_system.gd` in the `_initialize_attacks()` function:
- **damage** - How much HP to remove
- **cooldown** - Seconds before attack can be used again
- **range** - Detection radius in pixels
- **knockback** - Force applied to enemies
- **requires_combo** - How many hits needed before unlocking

---

## 🎯 How Attacks Work

### Attack Flow
1. Player presses attack button
2. Check if attack is on cooldown
3. Find all enemies within attack range using physics queries
4. Deal damage to each enemy hit
5. Apply knockback force
6. Play attack animation
7. Set cooldown timer

### Example: Manual Attack Call
```gdscript
var direction = Vector2.RIGHT
var success = attack_system.perform_attack("slash", self, direction)
if success:
	print("Attack hit!")
else:
	print("Still on cooldown or can't attack")
```

---

## 🚀 How to Run

1. **Open project in Godot 4**
2. **Click "Run" or press F5**
3. Press the game window
4. **Use controls to attack enemies**:
   - Move with Arrow Keys
   - Space = Slash
   - Shift = Power Attack
   - X = Cannon

---

## 🐛 Troubleshooting

### "Attack doesn't hit anything"
- Check collision layers: Player on layer 1, Enemies on layer 2
- Verify `collision_mask` in scripts includes both layers

### "No animations playing"
- Add SpriteFrames resource to AnimatedSprite2D nodes
- Check animation names match exactly

### "Enemies don't attack"
- Verify player is being found: `player = get_tree().root.get_child(0).find_child("Player", true, false)`
- Check detection_range is > 0

### "Cooldown bar isn't showing"
- Health UI needs to be attached to the main scene
- Verify health_ui.gd is running without errors

---

## 📝 Next Steps

1. ✅ **Attack System** - DONE
2. ❌ **Animations** - Need sprite sheets + SpriteFrames
3. ❌ **Sound Effects** - Add attack/hit sounds
4. ❌ **Visual Effects** - Add hit sparks, blood splatters
5. ❌ **Level Design** - Design treasure/mission objectives
6. ❌ **Boss Enemies** - Create stronger enemies with patterns

---

## 📚 Key Classes

### AttackSystem
```gdscript
perform_attack(attack_name, attacker, direction) → bool
can_attack(attack_name) → bool
get_cooldown_percent(attack_name) → float
```

### Player
```gdscript
take_damage(damage) → void
apply_knockback(force) → void
heal(amount) → void
```

### Enemy
```gdscript
take_damage(damage) → void
apply_knockback(force) → void
patrol() → void
chase() → void
attack() → void
```

---

## 💡 Tips

- **Combos are powerful!** Hit twice with Slash to unlock Power Attack for 30 damage
- **Power Attack has longer range** - great for grouped enemies
- **Cannon is a screen clearer** - use it when surrounded
- **Knockback is your friend** - push enemies away before they attack
- **Watch the cooldown** - faster attacks = more DPS but less damage per hit

Enjoy your pirate adventure! 🏴‍☠️
