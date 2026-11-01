extends Node
var failures := 0
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:
		failures += 1
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Integration checks require desktop graphics for MultiMesh buffers.")
		get_tree().quit(1)
		return
	var demo = load("res://showcase/main.tscn").instantiate()
	add_child(demo)
	# Allow the initial Horde._ready coroutine and navigation registration to finish.
	for frame in 4:
		await get_tree().physics_frame
	for population in [64,256,1024]:
		demo.count = population
		demo._spawn()
		for frame in 180:
			await get_tree().physics_frame
			if demo.horde.map_synchronized:
				break
		var h: Horde = demo.horde
		check(h.map_synchronized,"Navigation synchronized for %d" % population)
		check(h.alive_count == population,"Population %d" % population)
		var start := h.horde_positions[0]
		for frame in 30:
			await get_tree().physics_frame
		check(h.horde_positions[0].distance_to(start) > 0.001,"Simulation moves %d-agent population" % population)
		check(h.query_radius(h.horde_positions[0],2).has(0),"Spatial hash finds agent")
		check(h.multimesh.multimesh.visible_instance_count == population,"MultiMesh visibility matches population")
		check(h.animation_controller.track_ids.size() == population,"VAT capacity matches population")
	var h: Horde = demo.horde
	h.set_physics_process(false)
	var last_id := h.zombie_ids[h.alive_count-1]
	var removed := h.zombie_ids[0]
	h.die(0)
	check(h.resolve_zombie(last_id) == 0,"Swap removal preserves survivor stable ID")
	check(h.resolve_zombie(removed) == -1,"Removed stable ID cannot resolve")
	check(h.multimesh.multimesh.visible_instance_count == 1023,"Removal shrinks visible count without reallocating")
	h.rebuild_spatial_hash()
	var clock := h.animation_time
	h.process_mode = Node.PROCESS_MODE_DISABLED
	for frame in 4:
		await get_tree().process_frame
	check(h.animation_time == clock,"Pause freezes animation clock")
	h.process_mode = Node.PROCESS_MODE_INHERIT
	h.take_damage(0,100)
	check(h.horde_states[0] == Horde.base_zom_states.DYING,"Lethal damage enters death animation")
	check(h.begin_abduction(),"Brain abduction accepted")
	check(not h.begin_abduction(),"Duplicate abduction rejected")
	h.finish_abduction()
	check(h.abduction_finished,"Abduction lifecycle completed")
	demo.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("SMOKE failures=",failures)
	get_tree().call_deferred("quit",0 if failures == 0 else 1)
