extends Node3D
class_name Horde

signal zombie_died

# Export variables
#region
@export_group("Horde")
## Refrence to the player
@export var player : Player = null
## Number of enemies the hoard initially spawns
@export var enemies : int = 10
## Radius from hoards center that enemies can spawn from
@export var spawn_radius : float = 50.0
## Radius from hoards center that enemies can wander out to
@export var wander_radius : float = 150.0
@export_group("Brain")
@export var detection_distance : float = 100.0
@export var attention_distance : float = 200.0
@export var brain_wander_distance : float = 200.0
## Brain will not get closer than this to the player
@export var brain_min_dist : float = 15.0
@export var brain_idle_time : float = 8.0
## Maximum random delay before each zombie dies after its brain is abducted (seconds).
@export_range(0.0, 30.0, 0.1, "or_greater") var brain_death_delay_max : float = 3.0
@export_group("Base Enemy")
## Max health of the base enemy
@export var max_health : float = 15.00
## Walk speed of base enemy
@export var walk_speed : float = 3.0
## Run speed of the base enemy
@export var run_speed : float = 5.0 
@export var roam_radius : float = 20.0
## Factor of gravity applied to base zombies 
@export var gravity_factor : float = 2.0
## How much time the zombie waits in idle once it reaches its destination
@export var idle_wait_time : float = 1.5
## Uniform visual scale of each zombie; 0.6 puts its standing height below the van roof.
@export_range(0.1, 2.0, 0.01) var zombie_scale : float = 0.6
## The height offset applied to zombies from the ground. Applied only to the render and not actual position. 
@export var height_offsfet : float = 0.01
## Spawn zombies in the air so they fall to the ground, this determines how much 
@export var spawn_height_offset : float = 5.0
@export_group("Combat")
## Attack range of zombies
@export var attack_range : float = 2.0
## Attack speed placeholder for animation
@export var attack_speed : float = 0.9
## How much damage a zombie does
@export var attack_damage : float = 8.0
## Seconds spent sliding backward after a knockback hit.
@export_range(0.05, 2.0, 0.05) var knockback_duration : float = 0.4
## Group name PlayerAttackArea nodes register themselves under
@export var attack_group_name : String = "player_attacks"
## How many frames between combat scans , 1 = every frame
@export var combat_check_rate : int = 1
## Half-extents of the zombie's hit box, in local space (X, Y, Z)
@export var hitbox_half_extents : Vector3 = Vector3(1.0, 2.0, 0.8)
## Offset from hoard_positions[i] (feet) to the hitbox center
@export var hitbox_center_offset : Vector3 = Vector3(0, 1.0, 0)
@export_group("Performance")
## How many navigation path request per frame that the hoard allows
@export var path_requests_per_frame : int = 4
## Time a zombie waits until retrying a path request
@export var path_retry_time : float = 0.5
@export_group("Terrain Snapping")
## Collision mask for terrain
@export var terrain_collision_mask : int = 1
## How high up the zombie ground raycast ray begins from its origin
@export var ray_dist_above : float = 1.0
## How far the zombie ground raycast goes below its origin position
@export var ray_dist_below : float = 5.0
## Physical foot clearance above terrain; keep at zero to stand on the ground.
@export var height_snap_offset : float = 0.0
## Gravity force for the hoard 
@export var gravity : float = 9.8
## How close to the ground counts as grounded 
@export var ground_snap_distance : float = 0.15   
## Max fall velocity of zombie
@export var terminal_velocity : float = 40.0
@export_group("Spatial Hash")
## Grid size for spatial hash 
@export var grid_cell_size : float = 5.0
## How many frames before rebuiling the hash map of zombie positions 
@export var rebuild_rate : int = 1
@export_group("Avoidance")
## Radius zombies push away from each other within
@export var avoidance_radius : float = 2.5
## How strongly separation bends the movement direction (0 = no avoidance, 1 = equal weight to pathing)
@export var avoidance_strength : float = 0.6
## Weaker separation applied while attacking, just to stop total overlap around the player
@export var avoidance_attack_strength : float = 0.25
## Safety cap on neighbors processed per zombie per tick (protects against dense clumps in one cell)
@export var avoidance_max_neighbors : int = 8
@export_group("Animation")
## Index of each animation track in the OpenVAT JSON, in the order you baked them in Blender
## Baked order: 0=Idle, 1=Walk, 2=Run, 3=Swing, 4=Hit, 5=Die, 6=Dramatic Die
@export var track_roam : int = 1   # Walk
@export var track_idle : int = 0   # Idle
@export var track_chase : int = 2  # Run
@export var track_attack : int = 3 # Swing
@export var track_hit : int = 4    # Hit Reaction
@export var track_dying : int = 5  # Die
@export var track_dramatic_dying : int = 6 # Alternate death animation
## No dedicated fall/air animation baked yet - reuses Walk
@export var track_air : int = 1
## Minimum death hold; the full baked clip always finishes before removal.
@export var death_anim_duration : float = 0.0
## Minimum hit hold; the full baked clip always finishes before resuming.
@export var hit_anim_duration : float = 0.0
@export_range(0.0, 0.5, 0.01) var animation_blend_duration : float = 0.18
@export_range(0.0, 0.5, 0.01) var attack_blend_duration : float = 0.08
@export_range(0.0, 0.5, 0.01) var hit_blend_duration : float = 0.06
@export_range(0.0, 0.5, 0.01) var death_blend_duration : float = 0.08
## Maximum visual turning speed in degrees per second.
@export var turn_speed : float = 360.0
@export_group("Debug")
## If we are doing all the debug prints and stuff 
@export var debug : bool = false
@export var brain_debug : bool = false
## How much time in between debug prints if so 
@export var debug_print_time : float = 3.0
#endregion

# Scene refs 
@onready var multimesh: OpenVATMultiMeshInstance3D = $multimesh

# Lift the render origin so the scaled mesh's rest-pose feet sit at horde_positions.
var zombie_mesh_ground_offset : float = 0.0
var animation_time : float = 0.0
var animation_material : ShaderMaterial
const VATBlendController = preload("res://addons/openvat_animated/src/open_vat_blend_controller.gd")
var animation_controller = VATBlendController.new()
var previous_transforms : Array[Transform3D] = []
var current_transforms : Array[Transform3D] = []
var visual_yaws : PackedFloat32Array = []

# Enums
enum base_zom_states {IDLE, ROAM, CHASE, ATTACK, AIR, SHOCKED, CONFUSED, HIT, DYING, DIE, NONE, KNOCKBACK}
enum brain_states {IDLE, ROAM, CHASE}
enum attack_shape { SPHERE, CYLINDER, BOX }

# Brain Variables 
var brain_death_delays : Dictionary = {} # Stable zombie ID -> remaining seconds.
var brain_abducted : bool = false
var abduction_finished : bool = false
var brain_target 
var brain_path 
var brain_target_point_index : int = 0
var brain_idle_timer : float = 0.0
var brain_state : brain_states = brain_states.IDLE

# Horde Data 
#region
var zombie_ids: Array[int] = []
var next_zombie_id: int = 0
var alive_count : int = 0 # How many alive in the current hoard
var horde_health : PackedFloat32Array = [] # Health
var horde_positions : PackedVector3Array = [] # Current position in the world
var horde_directions : PackedVector3Array = []  # Last Facing Direction
var horde_paths : Array[PackedVector3Array] = [] # Path of points to path find to
var horde_target_point_index : PackedInt32Array = [] # Current index for point array
var horde_vertical_velocity : PackedFloat32Array = []
var horde_air_frames : PackedInt32Array = [] # consecutive ungrounded ticks
var horde_remaining_stuns : PackedInt32Array = []
#---FLAGS---
var effect_state  : Array[Dictionary] = []
var horde_grounded : Array[bool] = []
var horde_states : Array[base_zom_states] = []
#---TIMERS---
var horde_blind_timer : PackedFloat32Array = []
var horde_heat_timer : PackedFloat32Array = []
var horde_cold_timer : PackedFloat32Array = []
var horde_shock_timer : PackedFloat32Array = []
var horde_confuse_timer : PackedFloat32Array = []
var horde_poison_timer : PackedFloat32Array = []

var horde_attack_timer : PackedFloat32Array = []
var horde_attack_cycles : PackedInt32Array = []
var horde_death_timer : PackedFloat32Array = []
var horde_hit_timer : PackedFloat32Array = []
var horde_knockback_timer : PackedFloat32Array = []
var horde_knockback_remaining : PackedVector3Array = []
var horde_knockback_shocked : Array[bool] = []
var horde_idle_timers : PackedFloat32Array = []
var horde_path_retry_timer : PackedFloat32Array = [] # Retry timers for pathfinding
#endregion

# Navigation Info
## The hash map that holds our enemy positions. Each key is a cell on a grid of a size determined by grid_cell_size. It corrosponds to a array of zombies in the current cell and their current horde index. It is recreated periodically and how many frames it waits to recreate is determined by rebuild_rate. 
var spatial_hash : Dictionary = {} # Vector2 (cell) -> PackedInt32Array (zombie indices)
## Is the navigation map sync so we can rely query the server
var map_synchronized: bool = false

# Player info 
var player_found : bool  = false
var area_found_player : bool = false

# Zombie info
## How much a zombie would walk during the current frame
var walk_amount = 0
## How much a zombie would run during the current frame
var run_amount = 0

# Modifier variables for effects, loaded in the set_effects() funciton per zombie 
## Multiplied against damage taken in, so high vulnerbility means more damage.
var vuln_modifier = 1.0
## Multiplied against attack damage, so higher modifier means more damage.
var attack_red_modifier = 1.0
## Multiplied against speed, so higher modifier means faster zombie.
var speed_modifer = 1.0
## The damage per seconds all cumulatize effects apply. 
var effect_dps = 0.0

func _ready() -> void:
	NavigationServer3D.map_changed.connect(_on_map_changed)
	
	# Get our player node 
	var nodes = get_tree().get_nodes_in_group("player")
	
	# Get player from nodes if possible
	for node in nodes : 
		if node.has_method("van") : 
			player = node
			break
	
	# Set up zombies / brain 
	brain_idle_timer = brain_idle_time
	# Load the matching mesh, texture and tracks before spawning instances.
	setup_zombie_vat()
	# AABB stuff with the multimesh
	fix_vat_aabb()
	multimesh.custom_aabb = AABB(Vector3(-wander_radius, -10, -wander_radius), Vector3(wander_radius*2, 20, wander_radius*2))
	
	# The navigation map may already be synchronized when another horde is
	# added, so do not rely on receiving a new map_changed signal to spawn.
	await get_tree().physics_frame
	var map := get_world_3d().navigation_map
	if not NavigationServer3D.map_get_regions(map).is_empty() : 
		_wait_for_navmesh_ready(map)

func debug_print () : 
	if alive_count <= 0 : 
		return
	
	print("----------")
	print("Position : ", horde_positions[0])
	print("Path : ", horde_paths[0])
	print("Vertical Velocity : ", horde_vertical_velocity[0])
	print("State : ", horde_states[0])
	print("Grounded : ", horde_grounded[0])
	print("Hoard path retry timer : ", horde_path_retry_timer[0])
	print("Idle timer : ", horde_idle_timers[0])
	print("Mesh Count : ", multimesh.multimesh.instance_count)
	print("MM Position : ", multimesh.multimesh.get_instance_transform(0).origin)
	print("VAT custom data: ", multimesh.multimesh.get_instance_custom_data(0))
	print("VAT instance color: ", multimesh.multimesh.get_instance_color(0))

func debug_brain () : 
	print("Brain position : ", global_position)
	print("Zombie count : ", alive_count)

var debug_timer = debug_print_time
var hash_rebuild_wait = 1
var combat_check_wait = 1 
func _process(delta: float) -> void:
	animation_time += delta
	if animation_material == null:
		return
	if animation_controller.image != null:
		animation_controller.flush(animation_time)
	# Interpolate only transforms. Interpolating VAT metadata blends frame IDs
	# across unrelated clips, so the MultiMesh's built-in interpolation stays off.
	var fraction := Engine.get_physics_interpolation_fraction()
	var world_to_local := multimesh.global_transform.affine_inverse()
	for i in alive_count:
		var rendered := previous_transforms[i].interpolate_with(current_transforms[i], fraction)
		multimesh.multimesh.set_instance_transform(i, world_to_local * rendered)

func _physics_process(delta: float) -> void :
	debug_timer -= delta
	if debug_timer <= 0 : 
		if debug : 
			debug_print()
			debug_timer = debug_print_time
		if brain_debug :
			debug_brain()
	# need map to be sync'd 
	if not map_synchronized:
		return
	
	if brain_abducted and abduction_finished and alive_count == 0:
		queue_free()
		return
	if not brain_abducted:
		# Brain goes first
		player_found = detect_player() or area_found_player

		# manage brain transitions
		match brain_state :
			brain_states.IDLE :
				if player_found :
					brain_state = brain_states.CHASE

				elif brain_idle_timer <= 0:
					brain_state = brain_states.ROAM
			brain_states.ROAM :
				if player_found :
					brain_state = brain_states.CHASE
				elif brain_path == null or brain_path.is_empty() :
					brain_state = brain_states.IDLE
					brain_idle_timer = brain_idle_time
			brain_states.CHASE :
				if not player_found :
					brain_state = brain_states.IDLE
					brain_idle_timer = brain_idle_time
					brain_path = PackedVector3Array()
					brain_target_point_index = 0


		# Individual state logic
		match brain_state :
			brain_states.IDLE :
				brain_idle_timer -= delta
			brain_states.ROAM :
				if brain_path == null or brain_path.is_empty() :
					pick_brain_target()
				move_brain_along_path(walk_speed * delta)
			brain_states.CHASE :
				pick_brain_chase_target()
				move_brain_along_path(run_speed * delta)


	_update_brain_deaths(delta)
	walk_amount = walk_speed * delta
	run_amount = run_speed * delta
	
	# Process backwards because die() swap-removes a zombie and immediately
	# shrinks the visible MultiMesh instance count.
	for i in alive_count:
		previous_transforms[i] = current_transforms[i]
	for i in range(alive_count - 1, -1, -1) : 
		var new_state = base_zom_states.NONE
		
		# apply gravity
		apply_gravity(i, delta)
		
		var state_before_effects = horde_states[i]
		if state_before_effects != base_zom_states.DYING:
			set_effects(i, delta)
		if horde_states[i] != state_before_effects and horde_states[i] != base_zom_states.HIT and horde_states[i] != base_zom_states.DYING:
			sync_animation_track(i)
		# Effects can enter HIT/DYING during this tick; do not overwrite that
		# transition using a stale state captured before damage was applied.
		var current_state = horde_states[i]
		# Get our state transition
		match current_state : 
			base_zom_states.IDLE : 
				new_state = idle_tr(i, delta)
			base_zom_states.ROAM : 
				new_state = roam_tr(i)
			base_zom_states.CHASE : 
				new_state = chase_tr(i)
			base_zom_states.ATTACK : 
				new_state = attack_tr(i)
			base_zom_states.AIR : 
				new_state = air_tr(i)
			base_zom_states.KNOCKBACK:
				new_state = knockback_tr(i)
			base_zom_states.HIT : 
				new_state = hit_tr(i, delta)
			base_zom_states.DYING :
				new_state = dying_tr(i, delta)
		
		# Set new state if we have any 
		if new_state != base_zom_states.NONE : 
			current_state = new_state
			horde_states[i] = current_state
			
			if new_state == base_zom_states.CHASE : 
				enter_chase(i)
			elif new_state == base_zom_states.ATTACK:
				horde_attack_timer[i] = maxf(attack_speed, 0.001)
				horde_attack_cycles[i] = 0
			
			sync_animation_track(i)
		
		# Execute corrosponding logic 
		match current_state : 
			base_zom_states.IDLE : 
				idle(i, delta)
			base_zom_states.ROAM : 
				roam(i, delta)
			base_zom_states.CHASE : 
				chase(i, delta)
			base_zom_states.ATTACK : 
				attack(i, delta)
			base_zom_states.AIR : 
				air(i, delta)
			base_zom_states.KNOCKBACK:
				knockback(i, delta)
			base_zom_states.HIT : 
				hit(i, delta)
			base_zom_states.DYING :
				dying(i, delta)
			base_zom_states.SHOCKED:
				face_and_render(i)
			base_zom_states.DIE : 
				die(i)
		
	
	# process pending path request 
	process_path_requests()
	
	# Manage hash map re-construction
	hash_rebuild_wait -= 1 
	if hash_rebuild_wait <= 0 : 
		rebuild_spatial_hash()
		hash_rebuild_wait = rebuild_rate
	
	combat_check_wait -= 1
	if combat_check_wait <= 0:
		process_combat(delta * combat_check_rate)
		combat_check_wait = combat_check_rate

## Atomically claims this brain, including before navigation has finished loading.
func begin_abduction() -> bool:
	if brain_abducted or is_queued_for_deletion():
		return false
	brain_abducted = true
	brain_path = PackedVector3Array()
	pending_path_requests.clear()
	for i in alive_count:
		if horde_states[i] not in [base_zom_states.DYING, base_zom_states.DIE]:
			brain_death_delays[zombie_ids[i]] = randf_range(0.0, maxf(brain_death_delay_max, 0.0))
	_update_brain_deaths(0.0)
	return true

func _update_brain_deaths(delta: float) -> void:
	if brain_death_delays.is_empty():
		return
	for i in alive_count:
		var id := zombie_ids[i]
		if not brain_death_delays.has(id):
			continue
		if horde_states[i] in [base_zom_states.DYING, base_zom_states.DIE]:
			brain_death_delays.erase(id)
			continue
		brain_death_delays[id] -= delta
		if brain_death_delays[id] <= 0.0:
			brain_death_delays.erase(id)
			horde_health[i] = 0.0
			horde_states[i] = base_zom_states.DYING
			horde_death_timer[i] = death_anim_duration
			sync_animation_track(i)

func finish_abduction() -> void:
	abduction_finished = true
	$brain_mesh.hide()
	if alive_count == 0:
		queue_free()

#---BRAIN FUNCTIONS---
#region
## Returns true if the player is close enough to the brain and currently if there is nothing inbetween them
func detect_player () : 
	# get player pos 
	var player_pos = player.global_position
	var brain_pos = global_position
	var dist_to_player = brain_pos.distance_squared_to(player_pos)
	
	# If to far exit early 
	if dist_to_player > detection_distance * detection_distance: 
		return false
	
	# Create physics query 
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(brain_pos, player_pos)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var result = space_state.intersect_ray(query)
	
	if result : 
		return false
	else : 
		return true

func pick_brain_target () : 
	var map := get_world_3d().navigation_map
	var origin := NavigationServer3D.map_get_closest_point(map, global_position)
	var random_direction := Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized()
	var avoidance := Vector3.ZERO
	var attention_squared := attention_distance * attention_distance
	
	# Build an avoidance vector away from nearby treasure. Its opposite pulls
	# the random target toward treasure, weighted by distance and importance.
	for node in get_tree().get_nodes_in_group("treasure") : 
		if not is_instance_valid(node) or not node is Node3D : 
			continue
		if not "importance" in node : 
			continue
		
		var offset = global_position - node.global_position
		offset.y = 0.0
		var distance_squared = offset.length_squared()
		if distance_squared <= 0.0001 or distance_squared > attention_squared : 
			continue
		
		var distance := sqrt(distance_squared)
		var importance : float = clampf(float(node.importance), 0.0, 1.0)
		var weight := (attention_distance - distance) / attention_distance
		avoidance += (offset / distance) * weight * importance
	
	var target_direction := random_direction
	if avoidance.length_squared() > 0.0001 : 
		target_direction += -avoidance.normalized()
	
	if target_direction.length_squared() <= 0.0001 : 
		target_direction = random_direction
	else : 
		target_direction = target_direction.normalized()
	
	var desired_target := origin + target_direction * randf_range(brain_wander_distance * 0.5, brain_wander_distance)
	brain_target = NavigationServer3D.map_get_closest_point(map, desired_target)
	brain_path = NavigationServer3D.map_get_path(map, origin, brain_target, true)
	brain_target_point_index = 0

## Picks a point that chases the player without entering the brain's minimum distance
func pick_brain_chase_target () : 
	var map := get_world_3d().navigation_map
	var origin := NavigationServer3D.map_get_closest_point(map, global_position)
	var away_from_player := player.global_position.direction_to(global_position)
	away_from_player.y = 0.0
	
	if away_from_player.length_squared() <= 0.0001 : 
		away_from_player = Vector3.FORWARD
	else : 
		away_from_player = away_from_player.normalized()
	
	var desired_target := player.global_position + away_from_player * brain_min_dist
	var safe_target := NavigationServer3D.map_get_closest_point(map, desired_target)
	
	if brain_target is Vector3 and brain_target.distance_squared_to(safe_target) < 1.0 : 
		return
	
	brain_target = safe_target
	brain_path = NavigationServer3D.map_get_path(map, origin, brain_target, true)
	brain_target_point_index = 0

## Moves the brain toward the next point in its current navigation path
func move_brain_along_path(move_amount : float) : 
	if brain_path == null or brain_path.is_empty() : 
		return
	
	while brain_target_point_index < brain_path.size() : 
		var target_point : Vector3 = brain_path[brain_target_point_index]
		var flat_position := Vector3(global_position.x, 0.0, global_position.z)
		var flat_target := Vector3(target_point.x, 0.0, target_point.z)
		var distance_to_target := flat_position.distance_to(flat_target)
		
		if distance_to_target > move_amount : 
			var direction := flat_position.direction_to(flat_target)
			global_position.x += direction.x * move_amount
			global_position.z += direction.z * move_amount
			return
		
		global_position.x = target_point.x
		global_position.z = target_point.z
		move_amount -= distance_to_target
		brain_target_point_index += 1
	
	brain_path = PackedVector3Array()
	brain_target_point_index = 0

#endregion
#---HOARD FUNCTIONS---
#region
## Respawns the zombie horde with a fresh state
func spawn_horde() -> void:
	if brain_abducted:
		return
	# Reset horde data
	alive_count = enemies
	clear_horde_state()
	pending_path_requests.clear()
	zombie_ids.clear()
	for _i in enemies:
		zombie_ids.append(next_zombie_id)
		next_zombie_id += 1
	
	# Set for number of enemies in horde
	multimesh.multimesh.instance_count = enemies
	multimesh.multimesh.visible_instance_count = enemies
	
	var map := get_world_3d().navigation_map
	
	for i in enemies:
		
		# Get random offset for spawn radius
		var offset := Vector3(
			randf_range(-spawn_radius, spawn_radius),
			0.0,
			randf_range(-spawn_radius, spawn_radius)
		)
		
		# Get closest point on nav map 
		var spawn_pos = NavigationServer3D.map_get_closest_point(map, global_position + offset)
		spawn_pos.y += spawn_height_offset 
		
		# Set initial zombie info
		horde_vertical_velocity[i] = 0.0
		horde_health[i] = max_health
		horde_positions[i] = spawn_pos
		horde_directions[i] = Vector3.FORWARD
		horde_target_point_index[i] = 0
		horde_paths[i] = PackedVector3Array()
		horde_states[i] = base_zom_states.IDLE
		
		# Initialize every value the OpenVAT shader consumes:
		# R = per-zombie animation phase
		# G/B = animation start/end frames
		# A = visible opacity
		#print("[Horde] animation_tracks.size() = ", multimesh.animation_tracks.size())
		var animation_offset := randf() if multimesh.rand_anim_offset else 0.0
		animation_controller.reset_instance(i, track_idle, animation_time, animation_offset)
		horde_grounded[i] = true
		horde_air_frames[i] = 0 # consecutive ungrounded ticks
		horde_remaining_stuns[i] = 0
		# Reset timers 
		horde_blind_timer[i] = 0
		horde_heat_timer[i] = 0
		horde_cold_timer[i] = 0
		horde_shock_timer[i] = 0
		horde_confuse_timer[i] = 0
		horde_poison_timer[i] = 0
		horde_death_timer[i] = 0
		horde_hit_timer[i] = 0
		horde_attack_timer[i] = randf_range(0.0, attack_speed)
		horde_idle_timers[i] = randf_range(0.0, idle_wait_time)
		horde_path_retry_timer[i] = randf_range(0.0, path_retry_time) # desync retries
		
		effect_state[i] = {
			en.effect.HEAT : 
				0,
			en.effect.COLD : 
				0,
			en.effect.SHOCK : 
				0,
			en.effect.CONFUSE : 
				0,
			en.effect.POISON : 
				0,
			en.effect.BLIND : 
				0
		}
		
		# Use the same mesh facing at spawn and during movement.
		face_and_render(i)
		previous_transforms[i] = current_transforms[i]

## Clears the current hoard data buffers
func clear_horde_state () : 
	brain_death_delays.clear()
	previous_transforms.resize(enemies)
	current_transforms.resize(enemies)
	visual_yaws.resize(enemies)
	visual_yaws.fill(PI)
	animation_controller.initialize(multimesh.multimesh, animation_material, multimesh.animation_tracks, enemies)
	horde_health.clear()
	horde_health.resize(enemies)
	horde_positions.clear()
	horde_positions.resize(enemies)
	horde_directions.clear()
	horde_directions.resize(enemies)
	horde_target_point_index.clear()
	horde_target_point_index.resize(enemies)
	horde_path_retry_timer.clear()
	horde_path_retry_timer.resize(enemies)
	horde_paths.clear()
	horde_paths.resize(enemies)
	horde_vertical_velocity.clear()
	horde_vertical_velocity.resize(enemies)
	horde_grounded.clear()
	horde_grounded.resize(enemies)
	horde_idle_timers.clear()
	horde_idle_timers.resize(enemies)
	horde_states.clear()
	horde_states.resize(enemies)
	horde_attack_timer.clear()
	horde_attack_timer.resize(enemies)
	horde_attack_cycles.resize(enemies)
	horde_attack_cycles.fill(0)
	horde_air_frames.clear()
	horde_air_frames.resize(enemies)
	effect_state.clear()
	effect_state.resize(enemies)
	horde_death_timer.clear()
	horde_death_timer.resize(enemies)
	horde_knockback_timer.resize(enemies)
	horde_knockback_timer.fill(0.0)
	horde_knockback_remaining.resize(enemies)
	horde_knockback_remaining.fill(Vector3.ZERO)
	horde_knockback_shocked.resize(enemies)
	horde_knockback_shocked.fill(false)
	horde_hit_timer.clear()
	horde_hit_timer.resize(enemies)
	horde_cold_timer.clear()
	horde_cold_timer.resize(enemies)
	horde_heat_timer.clear()
	horde_heat_timer.resize(enemies)
	horde_confuse_timer.clear()
	horde_confuse_timer.resize(enemies)
	horde_shock_timer.clear()
	horde_shock_timer.resize(enemies)
	horde_poison_timer.clear()
	horde_poison_timer.resize(enemies)
	horde_blind_timer.clear()
	horde_blind_timer.resize(enemies)
	horde_remaining_stuns.clear()
	horde_remaining_stuns.resize(enemies)
## Applies gravity on zombie i and sets the is_grounded flag. Called before settings effects and transition
func apply_gravity(i: int, delta : float) :
	# zombie position
	var pos = horde_positions[i]
	
	# Create ray query for physics
	var space_state = get_world_3d().direct_space_state
	var ray_end = pos - Vector3.UP * ray_dist_below
	var ray_begin = pos + Vector3.UP * ray_dist_above
	
	var query := PhysicsRayQueryParameters3D.create(ray_begin, ray_end)
	query.collision_mask = terrain_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var ray_result := space_state.intersect_ray(query)
	
	# If we are debug, used this for debugging being on the ground
	# Visualizes the ray from enemy position to ground / collision
	if i == 0 and debug:
		$ray_begin.global_position = ray_begin
		$ray_end.global_position = ray_end
		visualize_ray(ray_begin, ray_end, ray_result)
	
	# enemy is dead, do nothing i guess 
	if ray_result == null : 
		return
	
	# If we hit nothing
	if ray_result.is_empty():
		# Just keep falling
		horde_grounded[i] = false
		horde_vertical_velocity[i] -= gravity * delta
		horde_vertical_velocity[i] = maxf(horde_vertical_velocity[i], -terminal_velocity) # bound fall velocity
		horde_air_frames[i] += 1
		pos.y +=horde_vertical_velocity[i] * delta
	
	else : # we did hit the ground
		var ground_y : float = ray_result.position.y + height_snap_offset
		var distance_to_ground = pos.y - ground_y
		
		# If we hit the ground this frame
		if distance_to_ground <= ground_snap_distance:
			# Close enough to ground - snap and stop falling.
			pos.y = ground_y
			horde_vertical_velocity[i] = 0.0
			horde_air_frames[i] = 0 
		else:
			# In the air - integrate fall speed
			horde_vertical_velocity[i] -= gravity * delta
			horde_vertical_velocity[i] = maxf(horde_vertical_velocity[i], -terminal_velocity)
			pos.y += horde_vertical_velocity[i] * delta
			horde_air_frames[i] += 1
		
		# Make sure agent doesn't fall through ground 
		if pos.y < ground_y:
				pos.y = ground_y
				horde_vertical_velocity[i] = 0.0
				horde_air_frames[i] = 0 
				horde_grounded[i] = true
		# Use the position after falling/clamping, not the old pre-fall distance.
		if pos.y - ground_y <= ground_snap_distance:
			horde_grounded[i] = true
		else:
			horde_grounded[i] = false
	# Write new position to zombie
	horde_positions[i] = pos


var pending_path_requests : PackedInt32Array = []
func queue_path_request(i: int) -> void:
	if i < 0 or i >= alive_count:
		return
	var id := zombie_ids[i]
	if not pending_path_requests.has(id):
		pending_path_requests.append(id)
## Requests own stable IDs, since die() compacts the instance arrays.
func process_path_requests() -> void:
	var processed := 0
	while processed < path_requests_per_frame and not pending_path_requests.is_empty():
		var id := pending_path_requests[0]
		pending_path_requests.remove_at(0)
		processed += 1
		var i := resolve_zombie(id)
		if i < 0:
			continue
		if is_blind(i):
			pick_blind_target(i)
		elif horde_states[i] == base_zom_states.CHASE:
			pick_player_target(i)
		else:
			pick_new_random_target(i)
		horde_idle_timers[i] = idle_wait_time
## Render the zombie i based on its current positional information
# The new VAT mesh faces +Z; use_model_front aligns +Z with its movement.
func face_and_render(i : int) -> void :
	var direction := horde_directions[i]
	if direction.length_squared() > 0.0001:
		var target_yaw := atan2(direction.x, direction.z)
		visual_yaws[i] = rotate_toward(visual_yaws[i], target_yaw, deg_to_rad(turn_speed) * get_physics_process_delta_time())
	var new_basis := Basis(Vector3.UP, visual_yaws[i]).scaled(Vector3.ONE * zombie_scale)
	var render_pos := horde_positions[i] + Vector3.UP * (height_offsfet + zombie_mesh_ground_offset * zombie_scale)
	# Store world transforms so moving the parent horde brain does not add
	# physics-tick steps to the interpolated movement.
	current_transforms[i] = Transform3D(new_basis, render_pos)

## Helper functions for setting vat aabb for rendering
func fix_vat_aabb() -> void:
	if multimesh == null or multimesh.multimesh == null:
		push_warning("Horde: missing OpenVAT MultiMesh.")
		return

	var mesh := multimesh.multimesh.mesh
	if mesh == null:
		push_warning("Horde: MultiMesh has no source mesh.")
		return

	# VAT stores Blender-space offsets added to the mesh's rest positions.
	var vat_min := Vector3(multimesh.min_values.x, multimesh.min_values.z, -multimesh.max_values.y)
	var vat_max := Vector3(multimesh.max_values.x, multimesh.max_values.z, -multimesh.min_values.y)
	var rest_bounds := mesh.get_aabb()
	mesh.custom_aabb = AABB(rest_bounds.position + vat_min, rest_bounds.size + vat_max - vat_min).grow(1.0)

	# Whole-horde local bounds. This prevents one combined MultiMesh draw call
	# from being incorrectly culled when instances spread away from its origin.
	multimesh.multimesh.custom_aabb = AABB(
		Vector3(-wander_radius, -10.0, -wander_radius),
		Vector3(wander_radius * 2.0, 30.0, wander_radius * 2.0)
	)

## Returns a avoidance vector for a given zombie, meant to help zombies not cluster and run into each other
func compute_avoidance(i: int) -> Vector3:
	# Use spatial map to get relevant neighbors
	var neighbors := get_neighbors(i, avoidance_radius)
	if neighbors.is_empty():
		return Vector3.ZERO
	
	# Current zombie position and avoidance
	var pos := horde_positions[i]
	var push := Vector3.ZERO
	var considered := 0
	
	# For all near zombies
	for n in neighbors:
		if considered >= avoidance_max_neighbors:
			break
	
		var other := horde_positions[n]
		var delta := Vector3(pos.x - other.x, 0.0, pos.z - other.z)
		var dist := delta.length()
		
		# Compute avoidance vector against all close enough zombies 
		if dist < 0.0001:
			# Exact overlap - deterministic nudge
			# so they don't sit stacked forever with a zero-length delta.
			delta = Vector3(cos(float(i) * 2.399963), 0.0, sin(float(i) * 2.399963))
			dist = 1.0
		elif dist >= avoidance_radius:
			continue
		
		var weight := (avoidance_radius - dist) / avoidance_radius # 0..1, stronger when closer
		push += (delta / dist) * weight
		considered += 1
	
	return push

## Get random target within brain wander range
func pick_new_random_target(i: int) -> void:
	var map := get_world_3d().navigation_map
	var origin := horde_positions[i]
	
	var random_offset := Vector3(
		randf_range(-roam_radius, roam_radius),
		0.0,
		randf_range(-roam_radius, roam_radius)
	)
	var desired_target := NavigationServer3D.map_get_closest_point(map, global_position) + random_offset
	var safe_target := NavigationServer3D.map_get_closest_point(map, desired_target)
	
	horde_paths[i] = NavigationServer3D.map_get_path(map, origin, safe_target, true)
	horde_target_point_index[i] = 0
	horde_path_retry_timer[i] = path_retry_time
## Get hook point from player van
func pick_player_target(i : int) -> void : 
	var map := get_world_3d().navigation_map
	var origin := horde_positions[i]
	
	var player_hook = player.get_hook_point(horde_positions[i], false)
	var desired_target := NavigationServer3D.map_get_closest_point(map, player_hook) 
	var safe_target := NavigationServer3D.map_get_closest_point(map, desired_target)
	
	horde_paths[i] = NavigationServer3D.map_get_path(map, origin, safe_target, true)
	horde_target_point_index[i] = 0
	horde_path_retry_timer[i] = path_retry_time
## Get new target with blind logic
func pick_blind_target(i : int) -> void : 
	var map := get_world_3d().navigation_map
	var origin := horde_positions[i]

	var random_offset := Vector3(
		randf_range(-7.5, 7.5),
		0.0,
		randf_range(-7.5, 7.5)
	)
	var desired_target := NavigationServer3D.map_get_closest_point(map, origin) + random_offset
	var safe_target := NavigationServer3D.map_get_closest_point(map, desired_target)

	horde_paths[i] = NavigationServer3D.map_get_path(map, origin, safe_target, true)
	horde_target_point_index[i] = 0
	horde_path_retry_timer[i] = path_retry_time
#endregion

#---ANIMATION FUNCTIONS---
#region
func setup_zombie_vat() -> void:
	# Each horde owns its mesh and material configuration.
	multimesh.multimesh = multimesh.multimesh.duplicate()
	var source := preload("res://art/anims/zom/zombie.glb").instantiate()
	var mesh_node := source as MeshInstance3D
	if mesh_node == null:
		mesh_node = source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh := mesh_node.mesh.duplicate() as ArrayMesh
	zombie_mesh_ground_offset = -mesh.get_aabb().position.y
	# A rest-pose shadow mesh cannot follow the VAT deformation.
	mesh.shadow_mesh = null
	var material := ShaderMaterial.new()
	material.shader = preload("res://addons/openvat_animated/shaders/openvat_instanced.gdshader")
	animation_material = material
	material.set_shader_parameter("vertex_animation_texture", preload("res://art/anims/zom/Zombie_Mesh.003_vat.exr"))
	# Keep the imported zombie appearance when replacing its material with VAT.
	var zombie_material := preload("res://resources/mats/zombie.tres")
	material.set_shader_parameter("albedo", zombie_material.albedo_color)
	material.set_shader_parameter("albedo_texture", zombie_material.albedo_texture)
	mesh.surface_set_material(0, material)
	multimesh.exported_mesh = mesh
	multimesh.openvat_json_config_file = "res://art/anims/zom/Zombie_Mesh.003-remap_info.json"
	multimesh.import_json()
	# This bake is zero-based; the addon imports legacy one-based frames.
	for animation in multimesh.animation_tracks:
		animation.startFrame += 1
		animation.endFrame += 1
	source.free()

func sync_animation_track(i: int) -> void:
	if i < 0 or i >= alive_count or i >= multimesh.multimesh.instance_count : 
		return
	
	var track := track_for_state(horde_states[i])
	if horde_states[i] == base_zom_states.DYING:
		# Death is terminal; select its variant once, even if synchronized again.
		var current_track: int = animation_controller.track_ids[i]
		if current_track == track_dying or current_track == track_dramatic_dying:
			return
		if randf() < 0.5:
			track = track_dramatic_dying
	if track < 0 or track >= multimesh.animation_tracks.size():
		if debug:
			print("[Horde] animation track ", track, " out of range for state ", horde_states[i])
		return
	var animation := multimesh.animation_tracks[track]
	# State changes sharing a clip (e.g. ROAM/AIR) preserve its phase.
	var should_loop: bool = animation.isLooping or horde_states[i] in [base_zom_states.ATTACK, base_zom_states.KNOCKBACK]
	if animation_controller.track_ids[i] == track and (animation_controller.destination_colors[i].r > 0.5) == should_loop:
		return
	var phase: float = animation_controller.destination_data[i].r if animation.isLooping else 0.0
	var rate := float(animation.framerate)
	var looping := -1
	var blend_duration := animation_blend_duration
	match horde_states[i]:
		base_zom_states.ATTACK:
			# Repeat Swing while attacking, without changing damage timing.
			phase = 0.0
			rate = float(animation.endFrame - animation.startFrame + 1) / maxf(attack_speed, 0.001)
			looping = 1
			blend_duration = attack_blend_duration
		base_zom_states.KNOCKBACK:
			looping = 1
			blend_duration = hit_blend_duration
		base_zom_states.HIT:
			horde_hit_timer[i] = maxf(hit_anim_duration, clip_duration(track))
			blend_duration = hit_blend_duration
		base_zom_states.DYING:
			horde_death_timer[i] = maxf(death_anim_duration, clip_duration(track))
			blend_duration = death_blend_duration
	animation_controller.request_clip(i, track, animation_time, blend_duration, phase, rate, looping, true)

func clip_duration(track: int) -> float:
	return animation_controller.clip_duration(track)

func track_for_state(s) -> int:
	match s:
		base_zom_states.IDLE:
			return track_idle
		base_zom_states.SHOCKED:
			return track_idle
		base_zom_states.ROAM:
			return track_roam
		base_zom_states.CHASE:
			return track_chase
		base_zom_states.ATTACK:
			return track_attack
		base_zom_states.AIR:
			return track_air
		base_zom_states.HIT, base_zom_states.KNOCKBACK:
			return track_hit
		base_zom_states.DYING:
			return track_dying
	return -1

#endregion
#---EFFECT FUCNTIONS---
#region
## set_effects sets the current modifier buffer values based on the effect_state of the zombie i 
func set_effects(i : int, delta : float) : 
	# reset state each frame 
	vuln_modifier = 1.0
	attack_red_modifier = 1.0
	speed_modifer = 1.0
	effect_dps = 0.0
	
	
	
	var eff_state = effect_state[i]
	for effect in eff_state.keys() : 
		match effect : 
			en.effect.HEAT : 
				if eff_state[effect] == 0 : 
					continue
				
				var timer = horde_heat_timer[i]
				timer -= delta
				if timer <= 0 : 
					eff_state[effect] = 0
					effect_state[i][effect] = 0
					timer = 0
				horde_heat_timer[i] = timer
				
				if eff_state[effect] == 1 : 
					effect_dps += DevSettings.heat_dps_1
					attack_red_modifier -= DevSettings.heat_attack_red_1
				if eff_state[effect] == 2 : 
					effect_dps += DevSettings.heat_dps_2
					attack_red_modifier -= DevSettings.heat_attack_red_2
				if eff_state[effect] == 3 : 
					effect_dps += DevSettings.heat_dps_3
					attack_red_modifier -= DevSettings.heat_attack_red_3
			en.effect.COLD : 
				
				if eff_state[effect] == 0 : 
					continue
				
				var timer = horde_cold_timer[i]
				timer -= delta
				if timer <= 0 : 
					eff_state[effect] = 0
					effect_state[i][effect] = 0
					timer = 0
				horde_cold_timer[i] = timer
				
				if eff_state[effect] == 1 : 
					speed_modifer -= DevSettings.cold_slow_1
					vuln_modifier += DevSettings.cold_vuln_1
				if eff_state[effect] == 2 : 
					speed_modifer -= DevSettings.cold_slow_2
					vuln_modifier += DevSettings.cold_vuln_2
				if eff_state[effect] == 3 : 
					speed_modifer -= DevSettings.cold_slow_3
					vuln_modifier += DevSettings.cold_vuln_3
			en.effect.CONFUSE : 
				var timer = horde_confuse_timer[i]
				timer -= delta
				if timer <= 0 : 
					eff_state[effect] = 0
					effect_state[i][effect] = 0
					timer = 0
				horde_confuse_timer[i] = timer
			en.effect.POISON : 
				if eff_state[effect] == 0 : 
					continue
				
				var timer = horde_poison_timer[i]
				timer -= delta
				if timer <= 0 : 
					eff_state[effect] = 0
					effect_state[i][effect] = 0
					timer = 0
				horde_poison_timer[i] = timer
				
				if eff_state[effect] == 1 : 
					speed_modifer -= DevSettings.poison_slow_1
					effect_dps += DevSettings.poison_dps_1
				if eff_state[effect] == 2 : 
					speed_modifer -= DevSettings.poison_slow_2
					effect_dps += DevSettings.poison_dps_2
				if eff_state[effect] == 3 : 
					speed_modifer -= DevSettings.poison_slow_3
					effect_dps += DevSettings.poison_dps_3
			en.effect.BLIND : 
				var timer = horde_blind_timer[i]
				timer -= delta
				if timer <= 0 : 
					eff_state[effect] = 0
					effect_state[i][effect] = 0
					timer = 0
				horde_blind_timer[i] = timer
			en.effect.SHOCK:
				var level: int = clampi(eff_state[effect], 0, 3)
				if level == 0:
					continue
				var durations = [DevSettings.stun_duration_1, DevSettings.stun_duration_2, DevSettings.stun_duration_3]
				var cooldowns = [DevSettings.stun_cooldown_1, DevSettings.stun_cooldown_2, DevSettings.stun_cooldown_3]
				var vulnerabilities = [DevSettings.stun_vuln_1, DevSettings.stun_vuln_2, DevSettings.stun_vuln_3]
				if horde_states[i] == base_zom_states.KNOCKBACK:
					vuln_modifier += vulnerabilities[level - 1]
					continue
				horde_shock_timer[i] -= delta
				if horde_shock_timer[i] <= 0.0:
					if horde_states[i] == base_zom_states.SHOCKED:
						horde_remaining_stuns[i] = maxi(horde_remaining_stuns[i] - 1, 0)
						horde_states[i] = base_zom_states.IDLE
						if horde_remaining_stuns[i] > 0:
							horde_shock_timer[i] = cooldowns[level - 1]
						else:
							effect_state[i][effect] = 0
					else:
						horde_states[i] = base_zom_states.SHOCKED
						horde_shock_timer[i] = durations[level - 1]
				if effect_state[i][effect] > 0:
					vuln_modifier += vulnerabilities[level - 1]
	
	speed_modifer = maxf(speed_modifer, 0.0)
	# Do our tick damage to see if zom dies on frame BEFORE transittion logic 
	if effect_dps != 0.0 : 
		take_damage(i, effect_dps * delta, en.effect.NONE, false)
## This function is what is called when a effect hits a enemy. Based on what the current level is, it sets the effect on the enemy
## and all its timers and parameters that are not shared. 
func raise_effect(i : int, effect : en.effect) : 
	# Look for transition logic
	var prev: int = mini(effect_state[i][effect], 2)
	
	match effect : 
		en.effect.HEAT : 
			if prev == 0 : 
				horde_heat_timer[i] += DevSettings.heat_duration_1
			if prev == 1 : 
				horde_heat_timer[i] += DevSettings.heat_duration_2
			if prev == 2 : 
				horde_heat_timer[i] += DevSettings.heat_duration_3
		en.effect.COLD : 
			if prev == 0 : 
				horde_cold_timer[i] += DevSettings.cold_duration_1
			if prev == 1 : 
				horde_cold_timer[i] += DevSettings.cold_duration_2
			if prev == 2 : 
				horde_cold_timer[i] += DevSettings.cold_duration
		en.effect.CONFUSE:
			horde_paths[i] = PackedVector3Array()
			horde_target_point_index[i] = 0
			pending_path_requests.erase(zombie_ids[i])
			if horde_states[i] in [base_zom_states.CHASE, base_zom_states.ATTACK, base_zom_states.ROAM]:
				horde_states[i] = base_zom_states.IDLE
				horde_idle_timers[i] = idle_wait_time
				sync_animation_track(i)
			var durations = [DevSettings.confuse_duration_1, DevSettings.confuse_duration_2, DevSettings.confuse_duration_3]
			horde_confuse_timer[i] += durations[prev]
		en.effect.POISON : 
			if prev == 0 : 
				horde_poison_timer[i] += DevSettings.poison_duration_1
			if prev == 1 : 
				horde_poison_timer[i] += DevSettings.poison_duratio_2
			if prev == 2 : 
				horde_poison_timer[i] += DevSettings.poison_duration_3
		en.effect.BLIND : 
			if prev == 0:
				horde_paths[i] = PackedVector3Array()
				horde_target_point_index[i] = 0
				queue_path_request(i)
			if prev == 0 : 
				horde_blind_timer[i] += DevSettings.blind_time_1
			if prev == 1 : 
				horde_blind_timer[i] += DevSettings.blind_time_2
			if prev == 2 : 
				horde_blind_timer[i] += DevSettings.blind_time_3
		en.effect.SHOCK : 
			if prev == 0 : 
				horde_remaining_stuns[i] += DevSettings.stun_amount_1
				horde_states[i] = base_zom_states.SHOCKED
				# set shock timer to time until cooldown for shock 
				horde_shock_timer[i] = DevSettings.stun_duration_1
			if prev == 1 : 
				horde_remaining_stuns[i] += DevSettings.stun_amount_2
				horde_states[i] = base_zom_states.SHOCKED
				# set shock timer to time until cooldown for shock 
				horde_shock_timer[i] = DevSettings.stun_duration_2
			if prev == 2 : 
				horde_remaining_stuns[i] += DevSettings.stun_amount_3
				horde_states[i] = base_zom_states.SHOCKED
				# set shock timer to time until cooldown for shock 
				horde_shock_timer[i] = DevSettings.stun_duration_3
	
	if effect == en.effect.SHOCK and i < horde_knockback_timer.size() and horde_knockback_timer[i] > 0.0:
		horde_knockback_shocked[i] = true
		horde_states[i] = base_zom_states.KNOCKBACK
	# Raise the marker 
	effect_state[i][effect] = mini(effect_state[i][effect] + 1, 3)

func is_blind(i : int) -> bool: 
	return effect_state[i][en.effect.BLIND] > 0

func is_confused(i : int) : 
	return effect_state[i][en.effect.CONFUSE] > 0


#endregion
#---STATE FUNCTIONS---
#region
func idle (i : int, delta : float) : 
	# Manage timer and if we should search for a path 
	if horde_idle_timers[i] > 0 :
		horde_idle_timers[i] -= delta
	
	if horde_idle_timers[i] <= 0 : 
		# queue for pathfinding
		queue_path_request(i)
		
	
	
	face_and_render(i)

func roam (i : int, delta : float) :
	if not has_valid_path(i):
		horde_paths[i] = PackedVector3Array()
		horde_target_point_index[i] = 0
		face_and_render(i)
		return
	# Get current zom info
	var idx = horde_target_point_index[i]
	var path = horde_paths[i]
	var target_point = path[idx]
	var current_pos = horde_positions[i]
	
	# 2D flattening of coordinates
	var flat_current := Vector3(current_pos.x, 0.0, current_pos.z)
	var flat_target := Vector3(target_point.x, 0.0, target_point.z)
	
	var direction := flat_current.direction_to(flat_target)
	var distance_to_target := flat_current.distance_to(flat_target)
	var move_amount = walk_amount * speed_modifer
	
	# If we'd reach the target this frame
	if distance_to_target <= move_amount:
		current_pos.x = target_point.x
		current_pos.z = target_point.z
		idx += 1
		# If we reached the end of the path 
		if idx >= path.size():
			horde_paths[i] = PackedVector3Array()
			horde_target_point_index[i] = 0
			horde_path_retry_timer[i] = 0.0
		# If we have more points, move onto the next
		else:
			horde_target_point_index[i] = idx
	else: 
		var move_dir := direction + compute_avoidance(i) * avoidance_strength
		if move_dir.length_squared() > 0.0001:
			move_dir = move_dir.normalized()
		else:
			move_dir = direction
		
		current_pos.x += move_dir.x * move_amount
		current_pos.z += move_dir.z * move_amount
		if move_dir.length_squared() > 0.01:
			horde_directions[i] = move_dir
	
	# Update position
	horde_positions[i] = current_pos
	face_and_render(i)

func chase (i : int, delta : float) : 
	# Refresh our path to the player periodically since they keep moving
	horde_path_retry_timer[i] -= delta
	if horde_path_retry_timer[i] <= 0.0 : 
		queue_path_request(i)
		horde_path_retry_timer[i] = path_retry_time
	
	var path = horde_paths[i]
	var idx = horde_target_point_index[i]
	
	if path.is_empty() or idx >= path.size() : 
		# Waiting on a path; gravity already ran at the start of this tick.
		face_and_render(i)
		return
	
	var target_point = path[idx]
	var current_pos = horde_positions[i]
	
	var flat_current := Vector3(current_pos.x, 0.0, current_pos.z)
	var flat_target := Vector3(target_point.x, 0.0, target_point.z)
	
	var direction := flat_current.direction_to(flat_target)
	var distance_to_target := flat_current.distance_to(flat_target)
	var move_amount = run_amount * speed_modifer
	
	if distance_to_target <= move_amount : 
		current_pos.x = target_point.x
		current_pos.z = target_point.z
		idx += 1
		if idx >= path.size():
			horde_paths[i] = PackedVector3Array()
			horde_target_point_index[i] = 0
		else:
			horde_target_point_index[i] = idx
	else : 
		var move_dir := direction + compute_avoidance(i) * avoidance_strength
		if move_dir.length_squared() > 0.0001:
			move_dir = move_dir.normalized()
		else:
			move_dir = direction
		
		current_pos.x += move_dir.x * move_amount
		current_pos.z += move_dir.z * move_amount
		if move_dir.length_squared() > 0.01 : 
			horde_directions[i] = move_dir
	
	horde_positions[i] = current_pos
	face_and_render(i)

func attack (i : int, delta : float) : 
	var to_player := player.global_position - horde_positions[i]
	var flat_dir := Vector3(to_player.x, 0.0, to_player.z)
	if flat_dir.length_squared() > 0.01 : 
		horde_directions[i] = flat_dir.normalized()
	
	# Mild separation so multiple attackers don't fully overlap
	var avoid := compute_avoidance(i)
	if avoid.length_squared() > 0.0001:
		var pos := horde_positions[i]
		var move_amount = avoidance_attack_strength * walk_speed * speed_modifer * delta
		var avoid_dir := avoid.normalized()
		pos.x += avoid_dir.x * move_amount
		pos.z += avoid_dir.z * move_amount
		horde_positions[i] = pos
	
	# Damage and the displayed swing use the same clock, including after pauses
	# and interrupted attacks. Count cycles instead of accumulating timer drift.
	var started: float = animation_controller.started_at(i)
	var interval := maxf(attack_speed, 0.001)
	var elapsed := maxf(animation_time - started, 0.0)
	var completed := floori(elapsed / interval)
	horde_attack_timer[i] = interval - fposmod(elapsed, interval)
	if completed > horde_attack_cycles[i]:
		horde_attack_cycles[i] = completed
		var dist_sq := horde_positions[i].distance_squared_to(player.global_position)
		# If our swing ends and we are close enough to player, damage them 
		if dist_sq <= attack_range * attack_range and player.has_method("take_damage") : 
			player.take_damage(attack_damage * attack_red_modifier)
	
	face_and_render(i)

func air (i : int, delta : float) : 
	face_and_render(i)

func hit (i : int, delta : float) : 
	# Frozen in place, playing the hit-reaction track. Gravity already ran
	# earlier this frame (apply_gravity is called unconditionally per zombie).
	face_and_render(i)

func dying (i : int, delta : float) : 
	# Frozen in place, playing the death track. Gravity already ran earlier
	# this frame (apply_gravity is called unconditionally per zombie), so a
	# corpse mid-fall still settles onto the ground while this plays.
	face_and_render(i)

func die (i : int) : 
	if i < zombie_ids.size():
		brain_death_delays.erase(zombie_ids[i])
	var last := alive_count - 1
	animation_controller.move_instance(last, i)
	if zombie_ids.size() == alive_count:
		zombie_ids[i] = zombie_ids[last]
		zombie_ids.pop_back()
	
	if i != last:
		horde_health[i] = horde_health[last]
		horde_positions[i] = horde_positions[last]
		horde_directions[i] = horde_directions[last]
		previous_transforms[i] = previous_transforms[last]
		current_transforms[i] = current_transforms[last]
		visual_yaws[i] = visual_yaws[last]
		horde_paths[i] = horde_paths[last]
		horde_target_point_index[i] = horde_target_point_index[last]
		horde_path_retry_timer[i] = horde_path_retry_timer[last]
		horde_vertical_velocity[i] = horde_vertical_velocity[last]
		horde_grounded[i] = horde_grounded[last]
		horde_idle_timers[i] = horde_idle_timers[last]
		horde_states[i] = horde_states[last]
		horde_attack_timer[i] = horde_attack_timer[last]
		horde_attack_cycles[i] = horde_attack_cycles[last]
		horde_death_timer[i] = horde_death_timer[last]
		horde_hit_timer[i] = horde_hit_timer[last]
		horde_knockback_timer[i] = horde_knockback_timer[last]
		horde_knockback_remaining[i] = horde_knockback_remaining[last]
		horde_knockback_shocked[i] = horde_knockback_shocked[last]
		horde_air_frames[i] = horde_air_frames[last]
		effect_state[i] = effect_state[last]
		horde_heat_timer[i] = horde_heat_timer[last]
		horde_cold_timer[i] = horde_cold_timer[last]
		horde_poison_timer[i] = horde_poison_timer[last]
		horde_blind_timer[i] = horde_blind_timer[last]
		horde_confuse_timer[i] = horde_confuse_timer[last]
		horde_shock_timer[i] = horde_shock_timer[last]
		horde_remaining_stuns[i] = horde_remaining_stuns[last]
		
		# Preserve the swapped zombie's animation phase and one-shot progress.
		multimesh.multimesh.set_instance_custom_data(i, multimesh.multimesh.get_instance_custom_data(last))
		multimesh.multimesh.set_instance_color(i, multimesh.multimesh.get_instance_color(last))
	
	alive_count -= 1
	if alive_count == 0 and not brain_abducted:
		queue_free()
	# Keep the allocation: resizing it clears all surviving animation data.
	multimesh.multimesh.visible_instance_count = alive_count
	emit_signal("zombie_died")

func has_valid_path(i: int) -> bool:
	return horde_target_point_index[i] >= 0 and horde_target_point_index[i] < horde_paths[i].size()

func idle_tr (i : int, delta : float) : 
	
	
	# check if on ground
	if horde_air_frames[i] > 3 :   
		return base_zom_states.AIR
	
	# If brain has found player, chase!
	if player_found and not is_confused(i) and not is_blind(i):
		return base_zom_states.CHASE
	
	# check if we have a path 
	if has_valid_path(i):
		return base_zom_states.ROAM
	
	return base_zom_states.NONE

func roam_tr (i : int) : 
	# check if on ground
	if horde_air_frames[i] > 3 :   
		return base_zom_states.AIR
	
	# If brain has found player, chase!
	if player_found and not is_confused(i) and not is_blind(i):
		return base_zom_states.CHASE
	
	if not has_valid_path(i):
		return base_zom_states.IDLE
	
	return base_zom_states.NONE

func chase_tr (i : int) : 
	
	if is_confused(i) or is_blind(i):
		return base_zom_states.IDLE
	
	if horde_air_frames[i] > 3 :   
		return base_zom_states.AIR
	if not player_found : 
		horde_paths[i] = PackedVector3Array()
		horde_target_point_index[i] = 0
		return base_zom_states.IDLE
	var dist_sq := horde_positions[i].distance_squared_to(player.global_position)
	if dist_sq <= attack_range * attack_range : 
		return base_zom_states.ATTACK
	return base_zom_states.NONE

func attack_tr (i : int) : 
	
	
	if horde_air_frames[i] > 3 :
		return base_zom_states.AIR
	
	if is_confused(i) or is_blind(i):
		return base_zom_states.IDLE
	
	var dist_sq := horde_positions[i].distance_squared_to(player.global_position)
	if not player_found and dist_sq > 20 * 20 : 
		horde_paths[i] = PackedVector3Array()
		horde_target_point_index[i] = 0
		return base_zom_states.IDLE
	
	
	if dist_sq > (attack_range * 1.15) * (attack_range * 1.15):
		return base_zom_states.CHASE
	
	return base_zom_states.NONE

func air_tr (i : int) : 
	if horde_grounded[i] : 
		if player_found and not is_blind(i) and not is_confused(i):
			return base_zom_states.CHASE
		if has_valid_path(i):
			return base_zom_states.ROAM
		return base_zom_states.IDLE
	return base_zom_states.NONE

func hit_tr (i : int, delta : float) : 
	var started: float = animation_controller.started_at(i)
	horde_hit_timer[i] = maxf(hit_anim_duration, clip_duration(track_hit)) - (animation_time - started)
	if horde_hit_timer[i] <= 0.0 :
		if horde_air_frames[i] > 3 :
			return base_zom_states.AIR
		if player_found and not is_blind(i) and not is_confused(i):
			return base_zom_states.CHASE
		if has_valid_path(i):
			return base_zom_states.ROAM
		return base_zom_states.IDLE
	return base_zom_states.NONE

func dying_tr (i : int, delta : float) : 
	var started: float = animation_controller.started_at(i)
	var track: int = animation_controller.track_ids[i]
	horde_death_timer[i] = maxf(death_anim_duration, clip_duration(track)) - (animation_time - started)
	if horde_death_timer[i] <= 0.0 :
		return base_zom_states.DIE
	return base_zom_states.NONE

func enter_chase(i : int) : 
	queue_path_request(i)
	horde_path_retry_timer[i] = path_retry_time
#endregion
# ---DAMAGE / COMBAT---
#region
func get_vulnerability(i: int) -> float:
	var cold: int = clampi(effect_state[i][en.effect.COLD], 0, 3)
	var shock: int = clampi(effect_state[i][en.effect.SHOCK], 0, 3)
	var cold_values = [0.0, DevSettings.cold_vuln_1, DevSettings.cold_vuln_2, DevSettings.cold_vuln_3]
	var shock_values = [0.0, DevSettings.stun_vuln_1, DevSettings.stun_vuln_2, DevSettings.stun_vuln_3]
	return 1.0 + cold_values[cold] + shock_values[shock]

func take_damage(i: int, dmg: float, effect_type : en.effect = en.effect.NONE, hit_reaction: bool = true) -> void:
	# If we have died
	if i < 0 or i >= alive_count:
		return
	if horde_states[i] == base_zom_states.DYING or horde_states[i] == base_zom_states.DIE:
		return
	
	if not effect_type == en.effect.NONE : 
		raise_effect(i, effect_type)
	
	horde_health[i] -= dmg * get_vulnerability(i)
	# If we die
	if horde_health[i] <= 0.0:
		if horde_states[i] != base_zom_states.DYING:
			horde_states[i] = base_zom_states.DYING
			horde_death_timer[i] = death_anim_duration
			sync_animation_track(i)
	elif hit_reaction and dmg > 0.0 and horde_states[i] not in [base_zom_states.HIT, base_zom_states.SHOCKED, base_zom_states.KNOCKBACK]:
		horde_states[i] = base_zom_states.HIT
		horde_hit_timer[i] = hit_anim_duration
		sync_animation_track(i)

func take_damage_in_radius(center: Vector3, radius: float, dmg: float) -> void:
	var r2 := radius * radius
	# iterate backwards since die() can swap-remove into index i
	for i in range(alive_count - 1, -1, -1):
		if horde_positions[i].distance_squared_to(center) <= r2:
			take_damage(i, dmg)
## Checks all attack area nodes, and if active process their hit area for zombies
func process_combat(delta: float) -> void:
	# For all active areas
	for node in get_tree().get_nodes_in_group(attack_group_name):
		if not is_instance_valid(node):
			continue
		var area := node as player_attack_area
		if not area or not area.is_active():
			continue
	
		var shape_data := area.get_shape_data()
		if shape_data.is_empty():
			continue
	
		apply_shape_damage(shape_data.type, shape_data.xform, shape_data.params, area.damage, area, delta)

## Returns zombie indices whose hitbox (a box centered at
## hoard_positions[i] + hitbox_center_offset, sized hitbox_half_extents,
## expanded by projectile_radius) intersects the segment from
## seg_start to seg_end.
func query_segment_vs_boxes(seg_start: Vector3, seg_end: Vector3, projectile_radius: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	for hit in query_segment_hits(seg_start, seg_end, projectile_radius):
		result.append(hit.index)
	return result

## Return ordered live-target hits with their fraction along the segment.
func query_segment_hits(seg_start: Vector3, seg_end: Vector3, projectile_radius: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var broad_pad := Vector3(hitbox_half_extents.x + projectile_radius, 0, hitbox_half_extents.z + projectile_radius)
	var world_min := Vector3(minf(seg_start.x, seg_end.x), 0, minf(seg_start.z, seg_end.z)) - broad_pad
	var world_max := Vector3(maxf(seg_start.x, seg_end.x), 0, maxf(seg_start.z, seg_end.z)) + broad_pad
	for i in query_aabb(world_min, world_max):
		if i < 0 or i >= alive_count or horde_states[i] in [base_zom_states.DYING, base_zom_states.DIE]:
			continue
		var center := horde_positions[i] + hitbox_center_offset
		var half := hitbox_half_extents + Vector3.ONE * projectile_radius
		var fraction := _segment_box_fraction(seg_start, seg_end - seg_start, center - half, center + half)
		if fraction >= 0.0:
			result.append({index = i, fraction = fraction})
	result.sort_custom(func(a, b): return a.fraction < b.fraction)
	return result

func _segment_intersects_aabb(seg_start: Vector3, seg_dir: Vector3, box_min: Vector3, box_max: Vector3) -> bool:
	return _segment_box_fraction(seg_start, seg_dir, box_min, box_max) >= 0.0

func _segment_box_fraction(seg_start: Vector3, seg_dir: Vector3, box_min: Vector3, box_max: Vector3) -> float:
	var t_min := 0.0
	var t_max := 1.0
	for axis in 3:
		var origin := seg_start[axis]
		var d := seg_dir[axis]
		var lo := box_min[axis]
		var hi := box_max[axis]
		if absf(d) < 0.0001:
			if origin < lo or origin > hi:
				return -1.0
		else:
			var t1 := (lo - origin) / d
			var t2 := (hi - origin) / d
			if t1 > t2:
				var tmp := t1
				t1 = t2
				t2 = tmp
			t_min = maxf(t_min, t1)
			t_max = minf(t_max, t2)
			if t_min > t_max:
				return -1.0
	return t_min

func apply_shape_damage(
	shape_type: int,
	shape_xform: Transform3D,
	shape_params: Dictionary,
	dmg: float,
	source: player_attack_area,
	delta: float
) -> void:
	# Transform the complete local bounds, then expand by the zombie hurt box.
	var local_half := Vector3.ONE * float(shape_params.get("radius", 0.0))
	if shape_type == attack_shape.CYLINDER:
		local_half.y = shape_params.half_height
	elif shape_type == attack_shape.BOX:
		local_half = shape_params.half_extents
	var bounds := shape_xform * AABB(-local_half, local_half * 2.0)
	var candidates := query_aabb(bounds.position - hitbox_center_offset - hitbox_half_extents, bounds.end - hitbox_center_offset + hitbox_half_extents)

	for i in candidates:
		if horde_states[i] in [base_zom_states.DYING, base_zom_states.DIE]:
			continue
		var is_hit := preload("res://scripts/enemies/horde_hit_geometry.gd").overlaps_box(
			shape_type, shape_xform, shape_params,
			horde_positions[i] + hitbox_center_offset, hitbox_half_extents)

		if is_hit and source.should_hit(self, zombie_ids[i], delta):
			if source.effect_type != en.effect.NONE:
				for stack in range(1, source.effect_stacks):
					raise_effect(i, source.effect_type)
			take_damage(i, dmg, source.effect_type)
			if source.knockback_factor > 0.0:
				var direction := (horde_positions[i] - shape_xform.origin).slide(Vector3.UP).normalized()
				start_knockback(i, direction * source.knockback_factor)

func start_knockback(i: int, displacement: Vector3) -> void:
	if horde_states[i] in [base_zom_states.DYING, base_zom_states.DIE] or displacement.is_zero_approx():
		return
	# Also supports hordes constructed directly by test/sandbox scripts.
	horde_knockback_timer.resize(horde_positions.size())
	horde_knockback_remaining.resize(horde_positions.size())
	horde_knockback_shocked.resize(horde_positions.size())
	if horde_states[i] != base_zom_states.KNOCKBACK:
		horde_knockback_shocked[i] = horde_states[i] == base_zom_states.SHOCKED
	horde_knockback_timer[i] = maxf(knockback_duration, 0.001)
	horde_knockback_remaining[i] = displacement
	horde_paths[i] = PackedVector3Array()
	horde_target_point_index[i] = 0
	horde_states[i] = base_zom_states.KNOCKBACK
	sync_animation_track(i)

func knockback(i: int, delta: float) -> void:
	var remaining := horde_knockback_timer[i]
	var next_time := maxf(remaining - delta, 0.0)
	# Quadratic ease-out: fast impact, smoothly slowing to a stop.
	var fraction := 1.0 - pow(next_time / maxf(remaining, 0.001), 2.0)
	var step := horde_knockback_remaining[i] * fraction
	var origin := horde_positions[i]
	var destination := origin + step
	if not step.is_zero_approx():
		var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.5, destination + Vector3.UP * 0.5, 1)
		var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
		if not obstruction.is_empty():
			var travel := maxf(origin.distance_to(obstruction.position - Vector3.UP * 0.5) - 0.1, 0.0)
			destination = origin + step.normalized() * minf(travel, step.length())
			next_time = 0.0
	horde_positions[i] = destination
	horde_knockback_remaining[i] -= step
	horde_knockback_timer[i] = next_time
	face_and_render(i)

func knockback_tr(i: int) -> base_zom_states:
	if horde_knockback_timer[i] > 0.0:
		return base_zom_states.NONE
	if horde_knockback_shocked[i]:
		return base_zom_states.SHOCKED
	if horde_air_frames[i] > 3:
		return base_zom_states.AIR
	if player_found and not is_blind(i) and not is_confused(i):
		return base_zom_states.CHASE
	return base_zom_states.IDLE

func _get_broad_radius(shape_type: int, p: Dictionary) -> float:
	match shape_type:
		attack_shape.SPHERE:
			return p.radius
		attack_shape.CYLINDER:
			return sqrt(p.radius * p.radius + p.half_height * p.half_height)
		attack_shape.BOX:
			return p.half_extents.length()
	return 0.0

#endregion

#---SPATIAL HASH---
#region
func cell_of(pos: Vector3) -> Vector2i:
	# bounds the position of a zombie to a 2D grid and sorts it in a bucket / cell 
	return Vector2i(floori(pos.x / grid_cell_size), floori(pos.z / grid_cell_size))

func rebuild_spatial_hash() -> void:
	# rebuild hash each call 
	spatial_hash.clear()
	for i in alive_count:
		var cell := cell_of(horde_positions[i])
		if not spatial_hash.has(cell):
			spatial_hash[cell] = PackedInt32Array()
		spatial_hash[cell].append(i)

# Returns array of indicies of zombies within radius of query
func query_radius(center: Vector3, radius: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	# How many cells we need to check from the center 
	var cell_radius := ceili(radius / grid_cell_size)
	# Get center cell 
	var center_cell := cell_of(center)
	var r2 := radius * radius
	
	# For each cell we need to check in each direction
	for dx in range(-cell_radius, cell_radius + 1):
		for dz in range(-cell_radius, cell_radius + 1):
			# If the hash doesn't have it then no zombies 
			var cell := center_cell + Vector2i(dx, dz)
			if not spatial_hash.has(cell):
				continue
			# Since hash exist, get all zombies in hash 
			for i in spatial_hash[cell]:
				# If in radius of circle, append zombie index 
				if horde_positions[i].distance_squared_to(center) <= r2:
					result.append(i)

	return result

func query_aabb(world_min: Vector3, world_max: Vector3) -> PackedInt32Array:
	var result := PackedInt32Array()
	var min_cell := cell_of(world_min)
	var max_cell := cell_of(world_max)

	for cx in range(min_cell.x, max_cell.x + 1):
		for cz in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(cx, cz)
			if not spatial_hash.has(cell):
				continue
			for i in spatial_hash[cell]:
				var p := horde_positions[i]
				if p.x >= world_min.x and p.x <= world_max.x and p.z >= world_min.z and p.z <= world_max.z:
					result.append(i)

	return result

func get_neighbors(i: int, radius: float) -> PackedInt32Array:
	var raw := query_radius(horde_positions[i], radius)
	var result := PackedInt32Array()
	for n in raw:
		if n != i:
			result.append(n)
	return result


#endregion

#---CONNECTED SIGNALS---
func _on_map_changed(map: RID) -> void:
	if map != get_world_3d().navigation_map or map_synchronized:
		return
	if NavigationServer3D.map_get_regions(map).is_empty():
		return
	_wait_for_navmesh_ready(map)

func _wait_for_navmesh_ready(map: RID) -> void:
	# A valid closest point can be ZERO. Require synchronized, queryable geometry.
	while is_inside_tree() and not map_synchronized:
		if NavigationServer3D.map_get_iteration_id(map) > 0 and NavigationServer3D.map_get_closest_point_owner(map, global_position).is_valid():
			map_synchronized = true
			spawn_horde()
			for i in alive_count:
				queue_path_request(i)
			return
		await get_tree().physics_frame

#---DEBUG---
#region
var debug_mesh_instance: MeshInstance3D
var debug_immediate_mesh: ImmediateMesh
var debug_material: StandardMaterial3D

func setup_debug_visualization() -> void:
	debug_mesh_instance = MeshInstance3D.new()
	debug_immediate_mesh = ImmediateMesh.new()
	debug_mesh_instance.mesh = debug_immediate_mesh
	
	debug_material = StandardMaterial3D.new()
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.vertex_color_use_as_albedo = true
	debug_material.no_depth_test = true # Ensures the ray is visible even through terrain
	debug_mesh_instance.material_override = debug_material
	
	add_child(debug_mesh_instance)

func visualize_ray(ray_begin: Vector3, ray_end: Vector3, hit_result: Dictionary) -> void:
	if not debug:
		return
		
	if not debug_mesh_instance:
		setup_debug_visualization()
		
	debug_immediate_mesh.clear_surfaces()
	debug_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Green if we hit the ground, Red if the ray is empty (missing the floor)
	var line_color = Color.GREEN if not hit_result.is_empty() else Color.RED
	
	debug_immediate_mesh.surface_set_color(line_color)
	debug_immediate_mesh.surface_add_vertex(ray_begin)
	debug_immediate_mesh.surface_add_vertex(ray_end if hit_result.is_empty() else hit_result.position)
	
	debug_immediate_mesh.surface_end()
#endregion


func _on_brain_auto_detect_body_entered(body: Node3D) -> void:
	if body.has_method("van") :
		area_found_player = true
		print("found player")


func _on_brain_auto_detect_body_exited(body: Node3D) -> void:
	if body.has_method("van") :
		area_found_player = false

## Stable handles survive array compaction in die().
func resolve_zombie(id: int) -> int:
	var index := zombie_ids.find(id)
	if index < 0 or index >= alive_count:
		return -1
	if horde_states[index] in [base_zom_states.DYING, base_zom_states.DIE]:
		return -1
	return index

## Status-only attacks do not cause a damage hit reaction.
func apply_drone_hit(index: int, damage: float, effect: en.effect) -> void:
	if index < 0 or index >= alive_count:
		return
	if horde_states[index] in [base_zom_states.DYING, base_zom_states.DIE]:
		return
	if damage > 0.0:
		take_damage(index, damage, effect)
	else:
		raise_effect(index, effect)
