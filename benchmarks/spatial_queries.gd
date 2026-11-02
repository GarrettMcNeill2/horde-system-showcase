extends Node
## Compares the production radius query with an equivalent full scan.
class QueryHorde extends Horde:
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _physics_process(_delta: float) -> void:
		pass

func full_scan(h: Horde, center: Vector3, radius: float) -> PackedInt32Array:
	var found := PackedInt32Array()
	var positions := h.horde_positions
	var radius_squared := radius * radius
	for i in positions.size():
		if positions[i].distance_squared_to(center) <= radius_squared:
			found.append(i)
	return found

func run_batch(h: Horde, hashed: bool) -> float:
	var start := Time.get_ticks_usec()
	if hashed:
		h.rebuild_spatial_hash()
	for center in h.horde_positions:
		if hashed:
			h.query_radius(center,1.6)
		else:
			full_scan(h,center,1.6)
	return float(Time.get_ticks_usec()-start)/1000.0

func _ready() -> void:
	var rows: Array = []
	for count in [64,256,1024]:
		for layout in ["spread","dense"]:
			var h := QueryHorde.new()
			h.alive_count = count
			h.grid_cell_size = 5
			var rng := RandomNumberGenerator.new()
			rng.seed = 73421
			var extent := 36.0 if layout == "spread" else 2.0
			for i in count:
				h.horde_positions.append(Vector3(rng.randf_range(-extent,extent),0,rng.randf_range(-extent,extent)))
			h.rebuild_spatial_hash()
			var candidates := 0
			for center in h.horde_positions:
				var a := h.query_radius(center,1.6)
				var b := full_scan(h,center,1.6)
				a.sort()
				if a != b:
					push_error("Query result mismatch")
					get_tree().quit(1)
					return
				var cell := h.cell_of(center)
				for x in range(-1,2):
					for z in range(-1,2):
						candidates += h.spatial_hash.get(cell+Vector2i(x,z),PackedInt32Array()).size()
			for warmup in 3:
				run_batch(h,true)
				run_batch(h,false)
			var hashed: Array[float] = []
			var scanned: Array[float] = []
			for sample in 11:
				if sample % 2 == 0:
					hashed.append(run_batch(h,true))
					scanned.append(run_batch(h,false))
				else:
					scanned.append(run_batch(h,false))
					hashed.append(run_batch(h,true))
			hashed.sort()
			scanned.sort()
			rows.append({"agents":count,"layout":layout,"full_scan_distance_tests":count*count,"hash_distance_tests":candidates,"hash_including_rebuild_median_ms":hashed[5],"full_scan_median_ms":scanned[5],"hash_samples_ms":hashed,"full_scan_samples_ms":scanned,"results_equal":true})
			h.free()
	var report := {"godot":Engine.get_version_info().string,"cpu":OS.get_processor_name(),"os":OS.get_name(),"date":"2026-11-01","seed":73421,"radius":1.6,"cell_size":5,"warmup_batches":3,"measured_batches":11,"method":"One radius query per agent; hash timing includes one rebuild. Static synthetic XZ positions. Query outputs checked against full scan. Timings exclude simulation and rendering.","rows":rows}
	var file := FileAccess.open("res://benchmarks/spatial-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	get_tree().quit()
