class_name OpenVATBlendController
extends RefCounted
## Two advancing VAT clips per instance. One controller owns one MultiMesh/material.
## While enabled, use this controller for track changes instead of update_instance_track().

var track_ids := PackedInt32Array()
var destination_data: Array[Color] = []
var destination_colors: Array[Color] = []
var source_data: Array[Color] = []
var source_colors: Array[Color] = []
var blend_starts: Array[float] = []
var blend_durations: Array[float] = []
var image: Image
var texture: ImageTexture
var dirty := false

var _multimesh: MultiMesh
var _material: ShaderMaterial
var _tracks: Array[OpenVATAnimationTrack] = []
var _active: Dictionary = {}


func initialize(multimesh: MultiMesh, material: ShaderMaterial, tracks: Array[OpenVATAnimationTrack], capacity: int) -> void:
	_multimesh = multimesh
	_material = material
	_tracks = tracks
	track_ids.resize(capacity)
	track_ids.fill(-1)
	destination_data.resize(capacity)
	destination_colors.resize(capacity)
	source_data.resize(capacity)
	source_colors.resize(capacity)
	blend_starts.resize(capacity)
	blend_durations.resize(capacity)
	_active.clear()
	# RGBAF preserves frame IDs, timestamps and rates; never use an 8-bit image.
	image = Image.create(maxi(capacity, 1), 3, false, Image.FORMAT_RGBAF)
	image.fill(Color(0, 0, 0, 0))
	texture = ImageTexture.create_from_image(image)
	_material.set_shader_parameter("blend_metadata", texture)
	_material.set_shader_parameter("use_animation_clock", true)
	_material.set_shader_parameter("use_clip_blending", true)
	dirty = false


func reset_instance(index: int, track: int, now: float, phase: float = 0.0, opacity: float = 1.0) -> bool:
	if not _valid_request(index, track):
		return false
	track_ids[index] = -1
	_active.erase(index)
	blend_durations[index] = 0.0
	image.set_pixel(index, 2, Color(0, 0, 0, 0))
	var data := _multimesh.get_instance_custom_data(index)
	data.a = clampf(opacity, 0.0, 1.0)
	_multimesh.set_instance_custom_data(index, data)
	dirty = true
	return request_clip(index, track, now, 0.0, phase)


## rate=0 uses baked fps. looping=-1 uses the clip's baked loop flag.
## Repeated requests preserve playback unless restart is explicitly true.
func request_clip(index: int, track: int, now: float, duration: float = 0.18, phase: float = 0.0, rate: float = 0.0, looping: int = -1, restart: bool = false) -> bool:
	if not _valid_request(index, track):
		return false
	if track_ids[index] == track and not restart:
		return false
	var clip := _tracks[track]
	var has_source := track_ids[index] >= 0 and duration > 0.0
	if has_source:
		# An interrupted mix cannot be represented exactly by two clips. Retain
		# its dominant contributor and preserve that contributor's live cursor.
		if not _active.has(index) or blend_weight(index, now) >= 0.5:
			source_data[index] = destination_data[index]
			source_colors[index] = destination_colors[index]
		blend_starts[index] = now
		blend_durations[index] = duration
		_active[index] = true
		var data := source_data[index]
		var color := source_colors[index]
		# Row 0: source bounds, start time, fps. Row 1: phase, loop, fade start/duration.
		image.set_pixel(index, 0, Color(data.g, data.b, color.g, color.b))
		image.set_pixel(index, 1, Color(data.r, color.r, now, duration))
		image.set_pixel(index, 2, Color(1, 0, 0, 0))
	else:
		_active.erase(index)
		blend_durations[index] = 0.0
		image.set_pixel(index, 2, Color(0, 0, 0, 0))
	track_ids[index] = track
	# Opacity is presentation data; preserve addon fades when changing a clip.
	var alpha := _multimesh.get_instance_custom_data(index).a
	destination_data[index] = Color(clampf(phase, 0.0, 1.0), clip.startFrame, clip.endFrame, alpha)
	var loops := clip.isLooping if looping < 0 else looping > 0
	destination_colors[index] = Color(1.0 if loops else 0.0, now, rate if rate > 0.0 else float(clip.framerate), 1.0)
	_multimesh.set_instance_custom_data(index, destination_data[index])
	_multimesh.set_instance_color(index, destination_colors[index])
	dirty = true
	return true


func blend_weight(index: int, now: float) -> float:
	if not _active.has(index):
		return 1.0
	var progress := clampf((now - blend_starts[index]) / blend_durations[index], 0.0, 1.0)
	return progress * progress * (3.0 - 2.0 * progress)


func started_at(index: int) -> float:
	return destination_colors[index].g


## Inclusive frame bounds: a non-looping clip reaches its last frame at (N-1)/fps.
func clip_duration(track: int) -> float:
	var clip := _tracks[track]
	return float(clip.endFrame - clip.startFrame) / maxf(clip.framerate, 0.001)


## Copy a surviving last slot into a removed slot before reducing visible count.
func move_instance(last: int, destination: int) -> void:
	if last != destination:
		track_ids[destination] = track_ids[last]
		destination_data[destination] = destination_data[last]
		destination_colors[destination] = destination_colors[last]
		source_data[destination] = source_data[last]
		source_colors[destination] = source_colors[last]
		blend_starts[destination] = blend_starts[last]
		blend_durations[destination] = blend_durations[last]
		_active.erase(destination)
		if _active.has(last):
			_active[destination] = true
		for row in 3:
			image.set_pixel(destination, row, image.get_pixel(last, row))
	_active.erase(last)
	track_ids[last] = -1
	image.set_pixel(last, 2, Color(0, 0, 0, 0))
	dirty = true


## Call once before drawing. Only transition changes/completions upload metadata.
func flush(now: float) -> void:
	_material.set_shader_parameter("animation_clock", now)
	for index: int in _active.keys():
		if now >= blend_starts[index] + blend_durations[index]:
			_active.erase(index)
			image.set_pixel(index, 2, Color(0, 0, 0, 0))
			dirty = true
	if dirty:
		texture.update(image)
		dirty = false


static func sampled_pose(data: Color, color: Color, now: float) -> Color:
	var count := maxf(data.b - data.g + 1.0, 1.0)
	var cursor := maxf(now - color.g, 0.0) * maxf(color.b, 0.001) + count * data.r
	cursor = fposmod(cursor, count) if color.r > 0.5 else clampf(cursor, 0.0, count - 1.0)
	var frame := data.g + floorf(cursor)
	var next_frame := frame + 1.0
	if next_frame > data.b:
		next_frame = data.g if color.r > 0.5 else data.b
	return Color(frame, next_frame, cursor - floorf(cursor), now)


func _valid_request(index: int, track: int) -> bool:
	return index >= 0 and index < track_ids.size() and index < _multimesh.instance_count and track >= 0 and track < _tracks.size()
