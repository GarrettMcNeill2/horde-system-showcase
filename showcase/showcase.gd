extends Node3D
## Standalone presentation harness. Horde logic is an unchanged source snapshot.
const HORDE = preload("res://scenes/enemies/horde.tscn")
var horde: Horde
var target: Player
var camera: Camera3D
var stats: Label
var overlay: CanvasLayer
var count := 256
var orbit := 0.65
var distance := 65.0
var paused := false
var grid_visible := true
var debug_grid: Node3D
var elapsed := 0.0
var capture_mode := false
var capture_stage := 0
var capture_frames := 0
var preset := "Overview"

func _ready() -> void:
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	seed(73421)
	_build_arena()
	_build_ui()
	_spawn()

func _material(color: Color, emission := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if emission:
		m.emission_enabled = true
		m.emission = color
	return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = pos
	return node

func _build_arena() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("101a29")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("94b9d1")
	env.environment.ambient_light_energy = 0.65
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("ffe2b6")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	_box(self, Vector3(0,-0.3,0), Vector3(124,0.5,124), _material(Color("17283b")))
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(124,0.5,124)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.3
	add_child(floor_body)
	var region := NavigationRegion3D.new()
	var nav := NavigationMesh.new()
	nav.vertices = PackedVector3Array([Vector3(-60,0,-60),Vector3(-60,0,60),Vector3(60,0,60),Vector3(60,0,-60)])
	nav.add_polygon(PackedInt32Array([0,1,2,3]))
	region.navigation_mesh = nav
	add_child(region)
	debug_grid = Node3D.new()
	add_child(debug_grid)
	var grid := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120,120)
	grid.mesh = plane
	var grid_material := ShaderMaterial.new()
	grid_material.shader = preload("res://showcase/grid.gdshader")
	grid.material_override = grid_material
	debug_grid.add_child(grid)
	grid.position.y = 0.005
	var rim := _material(Color("51c8cd"),true)
	for side in [-1,1]:
		_box(self,Vector3(side*61,0,0),Vector3(0.15,0.15,122),rim)
		_box(self,Vector3(0,0,side*61),Vector3(122,0.15,0.15),rim)
	target = Player.new()
	target.collision_layer = 2
	target.collision_mask = 0
	target.add_to_group("player")
	add_child(target)
	target.position = Vector3(12,0,4)
	_box(target,Vector3(0,0.65,0),Vector3(1.8,1.3,1.8),_material(Color("f3b456"),true))
	camera = Camera3D.new()
	camera.fov = 48
	camera.far = 400
	add_child(camera)
	_camera_update()

func _build_ui() -> void:
	overlay = CanvasLayer.new()
	add_child(overlay)
	var panel := PanelContainer.new()
	panel.position = Vector2(28,28)
	panel.custom_minimum_size = Vector2(340,0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.055,0.085,0.94)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.border_width_left = 3
	style.border_color = Color("59d4cb")
	panel.add_theme_stylebox_override("panel",style)
	overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Horde system"
	title.add_theme_font_size_override("font_size",28)
	column.add_child(title)
	stats = Label.new()
	stats.add_theme_font_size_override("font_size",17)
	column.add_child(stats)
	var controls := Label.new()
	controls.text = "Click arena  Move target\n1 / 2 / 3  64 / 256 / 1,024 agents\nSpace  Pause     R  Reset\nK  Damage pulse     B  Abduct brain\nG  Grid     Tab  Hide panel\n← / →  Orbit     Wheel  Zoom\nF12  Save screenshot"
	controls.add_theme_font_size_override("font_size",15)
	controls.modulate = Color("a8bacb")
	column.add_child(controls)

func _spawn() -> void:
	if is_instance_valid(horde):
		remove_child(horde)
		horde.queue_free()
	seed(73421)
	horde = HORDE.instantiate()
	horde.player = target
	horde.enemies = count
	horde.spawn_radius = 36
	horde.spawn_height_offset = 0
	horde.wander_radius = 120
	horde.detection_distance = 110
	horde.attention_distance = 140
	horde.path_requests_per_frame = 16
	horde.max_health = 15
	horde.brain_min_dist = 12
	horde.avoidance_radius = 1.6
	horde.grid_cell_size = 5
	horde.zombie_scale = 0.6
	add_child(horde)
	horde.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	elapsed = 0

func _camera_update() -> void:
	camera.position = Vector3(sin(orbit)*distance,distance*0.78,cos(orbit)*distance)
	camera.look_at(Vector3(0,0,0))

func _process(delta: float) -> void:
	if not paused:
		elapsed += delta
	if Input.is_physical_key_pressed(KEY_LEFT):
		orbit -= delta*0.6
	if Input.is_physical_key_pressed(KEY_RIGHT):
		orbit += delta*0.6
	_camera_update()
	if is_instance_valid(horde):
		stats.text = "%s\n%d agents · %d occupied cells\n%d pending paths · budget %d/tick\n%d FPS · %d rendered draw calls\nProcess %.2f ms · %s" % [preset,horde.alive_count,horde.spatial_hash.size(),horde.pending_path_requests.size(),horde.path_requests_per_frame,Engine.get_frames_per_second(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.TIME_PROCESS)*1000,"Paused" if paused else "Running"]
	if capture_mode and is_instance_valid(horde) and horde.map_synchronized:
		if capture_frames >= 120 and capture_stage == 0:
			capture_stage = 1
			await _capture("01-overview")
			preset = "Close view"
			distance = 31
			orbit = 0.9
		if capture_frames >= 200 and capture_stage == 1:
			capture_stage = 2
			await _capture("02-close-view")
			preset = "Spatial grid"
			distance = 78
			orbit = 0.15
		if capture_frames >= 260 and capture_stage == 2:
			capture_stage = 3
			await _capture("03-spatial-grid")
			var result := {"agents":horde.alive_count,"occupied_cells":horde.spatial_hash.size(),"renderer":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info().string,"draw_calls_whole_scene":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"note":"Capture-run observation, not a benchmark. Grid lines and UI contribute draw calls."}
			var file := FileAccess.open("res://media/capture-observation.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(result,"\t"))
			overlay.hide()
			distance = 47
			orbit = 0.65
		if capture_frames >= 280 and capture_stage == 3:
			capture_stage = 4
			await _capture("04-hero")
			get_tree().quit()

func _physics_process(_delta: float) -> void:
	if capture_mode and is_instance_valid(horde) and horde.map_synchronized:
		capture_frames += 1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(18,distance-4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(120,distance+4)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var origin := camera.project_ray_origin(event.position)
			var point = Plane(Vector3.UP,0).intersects_ray(origin,camera.project_ray_normal(event.position))
			if point != null:
				target.position = Vector3(clampf(point.x,-55,55),0,clampf(point.z,-55,55))
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3:
			count = {KEY_1:64,KEY_2:256,KEY_3:1024}[event.physical_keycode]
			_spawn()
		KEY_R:
			_spawn()
		KEY_SPACE:
			paused = not paused
			if is_instance_valid(horde):
				horde.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
		KEY_G:
			grid_visible = not grid_visible
			debug_grid.visible = grid_visible
		KEY_TAB:
			overlay.visible = not overlay.visible
		KEY_K:
			if is_instance_valid(horde):
				horde.take_damage_in_radius(target.position,12,30)
		KEY_B:
			if is_instance_valid(horde):
				horde.begin_abduction()
				horde.finish_abduction()
		KEY_F12:
			_capture("manual-%d" % Time.get_unix_time_from_system())

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://media")
	DirAccess.make_dir_recursive_absolute(folder)
	var error := get_viewport().get_texture().get_image().save_png(folder.path_join(label+".png"))
	print("CAPTURE ",label," result=",error)
