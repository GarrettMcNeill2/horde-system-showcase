extends Area3D
class_name player_attack_area

# enums
enum DamageMode { ONE_SHOT, TICK }

# Exports
## How much damage the area does 
@export var damage : float = 10.0
## Its damage mode 
@export var damage_mode : DamageMode = DamageMode.ONE_SHOT
## The areas associated effect type 
@export var effect_type : en.effect = en.effect.NONE
@export_range(1, 3, 1) var effect_stacks: int = 1
## Only used in TICK mode - seconds between repeat hits on the same target
@export var tick_interval : float = 0.25
## Scalar multiplied along vector of contact to apply knockback
@export var knockback_factor : float = 0.0

const GROUP_NAME := "player_attacks"

var active := false
var collision_shape : CollisionShape3D

# hit-state is owned here, not by the horde - keyed per requester (a horde node)
# so multiple hordes can independently track "have I hit this target yet"
var hit_sets : Dictionary = {}       # horde -> Dictionary[int, bool]      (ONE_SHOT)
var tick_timers : Dictionary = {}    # horde -> Dictionary[int, float]     (TICK)


func _ready() -> void:
	add_to_group(GROUP_NAME)
	collision_shape = find_collision_shape()
	if not collision_shape:
		push_warning("PlayerAttackArea '%s' has no CollisionShape3D child" % name)


func activate() -> void:
	active = true
	hit_sets.clear()
	tick_timers.clear()

func _physics_process(delta: float) -> void:
	if not active:
		return
	for horde in tick_timers:
		var timers: Dictionary = tick_timers[horde]
		for target_key in timers:
			timers[target_key] = maxf(0.0, timers[target_key] - delta)

func deactivate() -> void:
	active = false

func is_active() -> bool:
	return active and collision_shape != null


func find_collision_shape() -> CollisionShape3D:
	for child in get_children():
		if child is CollisionShape3D:
			return child
	return null


## Returns {type: int, xform: Transform3D, params: Dictionary} using the SAME
## int mapping as Horde.attack_shape: 0=SPHERE, 1=CYLINDER, 2=BOX
func get_shape_data() -> Dictionary:
	var shape := collision_shape.shape
	var xform := collision_shape.global_transform

	if shape is SphereShape3D:
		return {type = 0, xform = xform, params = {radius = shape.radius}}
	elif shape is CylinderShape3D:
		return {type = 1, xform = xform, params = {radius = shape.radius, half_height = shape.height * 0.5}}
	elif shape is BoxShape3D:
		return {type = 2, xform = xform, params = {half_extents = shape.size * 0.5}}

	push_warning("Unsupported shape on '%s': %s" % [name, shape])
	return {}


## Called by a horde. Returns true if this (horde, target_key) pair should
## be damaged right now, and updates internal state accordingly.
func should_hit(horde: Node, target_key: int, _delta: float) -> bool:
	match damage_mode:
		DamageMode.ONE_SHOT:
			if not hit_sets.has(horde):
				hit_sets[horde] = {}
			var is_set : Dictionary = hit_sets[horde]
			if is_set.has(target_key):
				return false
			is_set[target_key] = true
			return true

		DamageMode.TICK:
			if not tick_timers.has(horde):
				tick_timers[horde] = {}
			var timers : Dictionary = tick_timers[horde]
			var remaining : float = timers.get(target_key, 0.0)
			if remaining <= 0.0:
				timers[target_key] = tick_interval
				return true
			else:
				timers[target_key] = remaining
				return false

	return false
