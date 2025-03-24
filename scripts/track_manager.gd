extends Node3D

@export var track_normal_straight: PackedScene
@export var track_normal_curved: PackedScene
@export var track_normal_cross: PackedScene
@export var track_golden_straight: PackedScene
@export var track_golden_curved: PackedScene
@export var track_golden_cross: PackedScene
@export var cursor_mesh: MeshInstance3D  
@export var camera: Camera3D  

var selected_material = "normal"
var selected_track_type = "straight"
var grid_size = 2.0  
var placing_track = false  
var removing_tracks = false  
var rot = 0
var track_map = {}  
var preview_track = null  

func _ready():
	cursor_mesh.visible = true
	ensure_cursor_material()
	create_preview_track()

func _process(_delta):
	update_cursor_position()
	if placing_track:
		place_track()
	if removing_tracks:
		remove_track()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			placing_track = event.pressed
			if placing_track:
				place_track()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			removing_tracks = event.pressed
			if removing_tracks:
				remove_track()
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q: selected_material = "normal"; update_preview_track()
			KEY_E: selected_material = "golden"; update_preview_track()
			KEY_1: selected_track_type = "straight"; update_preview_track()
			KEY_2: selected_track_type = "curved"; update_preview_track()
			KEY_3: selected_track_type = "cross"; update_preview_track()
			KEY_R: rotate_preview_track()

func update_cursor_position():
	if not camera:
		print("Error: Camera is not assigned!")
		return
	
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_position = result.position
		var snapped_position = snap_to_grid(hit_position)
		cursor_mesh.global_transform.origin = snapped_position
		set_cursor_color(is_placeable(snapped_position))

		if preview_track:
			preview_track.global_transform.origin = snapped_position
			preview_track.visible = is_placeable(snapped_position)
			preview_track.rotation_degrees.y = rot

func place_track():
	var grid_pos = snap_to_grid(cursor_mesh.global_transform.origin)
	
	if track_map.has(grid_pos):
		return
	
	if is_placeable(grid_pos):
		var track_scene = get_selected_track_scene()
		var new_track = track_scene.instantiate()
		new_track.global_transform.origin = grid_pos
		new_track.rotation_degrees.y = rot
		
		add_child(new_track)
		track_map[grid_pos] = new_track

func remove_track():
	var grid_pos = snap_to_grid(cursor_mesh.global_transform.origin)
	if track_map.has(grid_pos):
		track_map[grid_pos].queue_free()
		track_map.erase(grid_pos)

func rotate_preview_track():
	rot = (rot + 90) % 360
	if preview_track:
		preview_track.rotation_degrees.y = rot

func ensure_cursor_material():
	if not cursor_mesh.get_surface_override_material(0):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, 0.5)
		mat.flags_transparency = true
		cursor_mesh.set_surface_override_material(0, mat)

func set_cursor_color(is_valid):
	var mat = cursor_mesh.get_surface_override_material(0)
	if mat:
		mat.albedo_color = Color(0, 1, 0, 0.5) if is_valid else Color(1, 0, 0, 0.5)

func is_placeable(position):
	return not track_map.has(position)  

func get_selected_track_scene():
	var track_dict = {
		"normal": {
			"straight": track_normal_straight,
			"curved": track_normal_curved,
			"cross": track_normal_cross
		},
		"golden": {
			"straight": track_golden_straight,
			"curved": track_golden_curved,
			"cross": track_golden_cross
		}
	}
	return track_dict[selected_material][selected_track_type]

func create_preview_track():
	if preview_track:
		preview_track.queue_free()
	preview_track = get_selected_track_scene().instantiate()
	preview_track.visible = false
	add_child(preview_track)

func update_preview_track():
	if preview_track:
		preview_track.queue_free()
	create_preview_track()

func snap_to_grid(position):
	return Vector3(snapped(position.x, grid_size), 0, snapped(position.z, grid_size))
