extends Node3D

const Controller = preload("res://addons/openvat_animated/src/open_vat_blend_controller.gd")
var failures := 0


func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)


func _ready() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("OpenVAT blending tests require a graphical renderer.")
		get_tree().quit(1)
		return
	var tracks: Array[OpenVATAnimationTrack] = []
	for definition in [["Moving", 0, 1, 1, false], ["Still", 2, 2, 1, true], ["Other", 0, 1, 2, true]]:
		var track := OpenVATAnimationTrack.new()
		track.set_track(definition[0], definition[1], definition[2], definition[3], definition[4])
		tracks.append(track)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.instance_count = 2
	for index in 2:
		mm.set_instance_custom_data(index, Color(0, 0, 1, 1))
	var material := ShaderMaterial.new()
	material.shader = preload("res://addons/openvat_animated/shaders/openvat_instanced.gdshader")
	var controller := Controller.new()
	controller.initialize(mm, material, tracks, 2)
	controller.reset_instance(0, 0, 0.0)
	controller.request_clip(0, 1, 0.0, 2.0)
	var first_pose := Controller.sampled_pose(controller.source_data[0], controller.source_colors[0], 0.25)
	var later_pose := Controller.sampled_pose(controller.source_data[0], controller.source_colors[0], 0.75)
	check(is_equal_approx(first_pose.b, 0.25) and is_equal_approx(later_pose.b, 0.75), "Outgoing clip keeps advancing during a crossfade")
	check(is_equal_approx(controller.blend_weight(0, 1.0), 0.5), "Crossfade reaches equal weights halfway through")
	var started: float = controller.started_at(0)
	check(not controller.request_clip(0, 1, 0.5) and controller.started_at(0) == started, "Same-clip requests preserve playback and blend progress")
	controller.request_clip(0, 2, 0.25, 2.0)
	check(controller.source_data[0].g == 0 and controller.source_colors[0].b == 1 and controller.source_colors[0].g == 0, "Early interruption retains the dominant outgoing clip and its cursor")
	controller.request_clip(0, 1, 1.75, 2.0)
	check(controller.source_colors[0].b == 2 and is_equal_approx(controller.source_colors[0].g, 0.25), "Late interruption retains the dominant destination and its independent rate")
	check(controller.request_clip(0, 1, 2.0, 0.0, 0.0, 0.0, -1, true), "Explicit same-clip restart is supported")
	check(controller.started_at(0) == 2.0 and controller.blend_weight(0, 2.0) == 1.0, "Zero-duration request switches immediately")
	controller.flush(2.0)
	check(not controller.dirty and controller.image.get_pixel(0, 2).r == 0, "Immediate switch clears transition metadata")
	check(not controller.request_clip(-1, 0, 0) and not controller.request_clip(0, 99, 0), "Invalid instance and track requests are rejected")
	controller.reset_instance(1, 0, 0.0)
	controller.request_clip(1, 1, 0.0, 2.0)
	controller.move_instance(1, 0)
	check(is_equal_approx(controller.blend_weight(0, 0.5), 0.15625) and controller.track_ids[1] == -1, "Compaction moves the fade and clears its old slot")
	controller.flush(2.0)
	check(controller.image.get_pixel(0, 2).r == 0, "Completed fades retire their outgoing sampling path")
	controller.reset_instance(0, 0, 0.0)
	controller.request_clip(0, 1, 0.0, 2.0)
	controller.flush(0.75)
	check(not controller.dirty, "Clock-only flushes do not dirty metadata")
	var paused_weight: float = controller.blend_weight(0, 0.75)
	controller.flush(0.75)
	check(controller.blend_weight(0, 0.75) == paused_weight and not controller.dirty, "An unchanged game clock preserves fade progress")
	var independent := Controller.new()
	var independent_material := material.duplicate() as ShaderMaterial
	var independent_mm := mm.duplicate() as MultiMesh
	independent.initialize(independent_mm, independent_material, tracks, 2)
	independent.reset_instance(0, 2, 10.0)
	independent.flush(11.0)
	check(controller.track_ids[0] == 1 and controller.started_at(0) == 0 and material.get_shader_parameter("animation_clock") == 0.75, "Independent controllers isolate clip requests, clocks and materials")
	await verify_rendered_motion(mm, material, controller)
	# Empty hordes still bind a valid texture, and resetting capacity clears old fades.
	controller.initialize(mm, material, tracks, 0)
	check(controller.image.get_width() == 1 and not controller.request_clip(0, 0, 0), "Zero-instance controller allocates a valid empty buffer")
	controller.initialize(mm, material, tracks, 2)
	controller.reset_instance(0, 1, 3.0)
	check(controller.blend_weight(0, 3.0) == 1 and controller.track_ids[1] == -1, "Respawn clears old clips and active transitions")
	print("OpenVAT blending tests: ", failures, " failure(s)")
	get_tree().quit(0 if failures == 0 else 1)


func verify_rendered_motion(mm: MultiMesh, material: ShaderMaterial, controller) -> void:
	# A known VAT: source moves one unit right over one second; destination is
	# stationary. A frozen source would remain at x=0 and fail the pixel check.
	var vat := Image.create(1, 6, false, Image.FORMAT_RGBAF)
	vat.fill(Color(0, 0, 0, 1))
	vat.set_pixel(0, 1, Color(1, 0, 0, 1))
	for row in range(3, 6):
		vat.set_pixel(0, row, Color(0.5, 0, 0.5, 1))
	material.set_shader_parameter("vertex_animation_texture", ImageTexture.create_from_image(vat))
	material.set_shader_parameter("min_values", Vector3.ZERO)
	material.set_shader_parameter("max_values", Vector3.ONE)
	var white := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	material.set_shader_parameter("albedo_texture", ImageTexture.create_from_image(white))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.15, -0.15, 0), Vector3(0.15, -0.15, 0), Vector3(0.15, 0.15, 0), Vector3(-0.15, 0.15, 0)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var vat_uv := Vector2(0.5, 1.0 / 12.0)
	arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array([vat_uv, vat_uv, vat_uv, vat_uv])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	mm.mesh = mesh
	mm.visible_instance_count = 1
	mm.set_instance_transform(0, Transform3D.IDENTITY)
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = mm
	visual.custom_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	add_child(visual)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position = Vector3(0, 0, 4)
	camera.environment = Environment.new()
	camera.environment.background_mode = Environment.BG_COLOR
	camera.environment.background_color = Color.BLACK
	camera.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	camera.environment.ambient_light_color = Color.WHITE
	camera.environment.ambient_light_energy = 1.0
	add_child(camera)
	var previous_x := 0.0
	for now in [0.25, 0.75, 2.1]:
		controller.flush(now)
		for frame in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var rendered := get_viewport().get_texture().get_image()
		var sum_x := 0.0
		var count := 0
		for y in rendered.get_height():
			for x in rendered.get_width():
				if rendered.get_pixel(x, y).r > 0.2:
					sum_x += x
					count += 1
		check(count > 0, "Crossfade shader draws visible geometry at %.2fs" % now)
		if count == 0:
			continue
		var centroid := sum_x / count
		var progress := clampf(now / 2.0, 0, 1)
		var weight := progress * progress * (3.0 - 2.0 * progress)
		var expected_offset := minf(now, 1.0) * (1.0 - weight)
		var expected_x := rendered.get_width() * 0.5 + expected_offset * rendered.get_height() / camera.size
		check(absf(centroid - expected_x) < 3.0, "Rendered vertex position matches two moving clip samples at %.2fs" % now)
		if now == 0.75:
			check(centroid > previous_x + 10, "Rendered outgoing animation advances instead of freezing")
		previous_x = centroid
		rendered.save_png("res://.godot/vat_blend_%.2f.png" % now)
