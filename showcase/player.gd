extends CharacterBody3D
class_name Player
## Minimal adapter for the production Horde player contract.
var damage_received := 0.0
func van() -> void:
	pass
func get_hook_point(origin: Vector3, _unused: bool) -> Vector3:
	return global_position + global_position.direction_to(origin) * 1.2
func take_damage(amount: float) -> void:
	damage_received += amount
