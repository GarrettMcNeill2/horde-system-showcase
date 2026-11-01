extends Node

## Effect settings for how drastic the effects effect enemies. Variables are contained in their subgroup, being 
## effect_type_variable_level, where level goes form 1-3 ( least to most intense ) 
@export_group("Effects Settings")
@export_subgroup("Heat")
# Damage per second of heat
@export var heat_dps_1 : float = 0.5
@export var heat_dps_2 : float = 1.5
@export var heat_dps_3 : float = 4.0
# How much of the zombies attack gets reducted
@export var heat_attack_red_1 : float = 0.1
@export var heat_attack_red_2: float = 0.2
@export var heat_attack_red_3 : float = 0.4
# How many seconds the effect is supposed to last
@export var heat_duration_1 : float = 1.8
@export var heat_duration_2 : float = 1.1
@export var heat_duration_3 : float = 2.1
@export_subgroup("Shock")
# How many stuns are applied per layer
@export var stun_amount_1 : int = 2
@export var stun_amount_2 : int = 3
@export var stun_amount_3 : int = 4
# How long a individual stun lasts 
@export var stun_duration_1 : float = 0.2
@export var stun_duration_2 : float = 0.3
@export var stun_duration_3 : float = 0.55
# Period between each stun
@export var stun_cooldown_1 : float = 1.8
@export var stun_cooldown_2 : float = 1.5
@export var stun_cooldown_3 : float = 0.8
# What it sets the vuln modifier to
@export var stun_vuln_1 : float = 0.1
@export var stun_vuln_2: float = 0.2
@export var stun_vuln_3 : float = 0.4
@export_subgroup("Confusion")
@export var confuse_duration_1: float = 2.0
@export var confuse_duration_2: float = 3.0
@export var confuse_duration_3: float = 4.0
@export_subgroup("Blind")
# How long the zombie remains blinded 
@export var blind_time_1 : float = 2.3
@export var blind_time_2 : float = 2.2
@export var blind_time_3 : float = 3.7
@export_subgroup("Poison")
# Damage per second 
@export var poison_dps_1 : float = 0.2
@export var poison_dps_2 : float = 0.7
@export var poison_dps_3 : float = 6.0
# What factor slow is set to for zombie 
@export var poison_slow_1 : float = 0.1
@export var poison_slow_2 : float = 0.3
@export var poison_slow_3 : float = 0.5
# How long the effect last
@export var poison_duration_1 : float = 2.1
@export var poison_duratio_2 : float = 1.8
@export var poison_duration_3 : float = 3.1
@export_subgroup("Cold")
# How much is taken from speed factor ( 0.2 slow means speed is at 80% ) 
@export var cold_slow_1 : float = 0.2
@export var cold_slow_2 : float = 0.5
@export var cold_slow_3 : float = 0.8
# What it adds to vuln modifier for zombie 
@export var cold_vuln_1 : float = 0.1
@export var cold_vuln_2: float = 0.15
@export var cold_vuln_3 : float = 0.5
# How long the effect last 
@export var cold_duration_1 : float = 2.0
@export var cold_duration_2 : float = 2.0
@export var cold_duration : float = 4.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
