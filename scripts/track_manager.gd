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
var last_track = null  
var last_track_pos = null  
var second_last_track = null  
var second_last_track_pos = null  
var grid_size = 2.0  
var placing_track = false  
var preview_track = null  
var track_map = {}  
var removing_tracks = false  

func _ready():
	cursor_mesh.visible = true
	ensure_cursor_material()
	create_preview_track()

func _process(_delta):
	update_cursor_position()
	if placing_track and is_placeable(cursor_mesh.global_transform.origin):
		place_track(true)
	if removing_tracks:
		remove_track()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				placing_track = true  
				place_track(false)  
			else:
				placing_track = false  
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				removing_tracks = true
				remove_track()
			else:
				removing_tracks = false

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q: selected_material = "normal"; update_preview_track()
			KEY_E: selected_material = "golden"; update_preview_track()
			KEY_R: cursor_mesh.rotation_degrees.y += 90  

func update_cursor_position():
	if camera == null:
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

func place_track(dragging):
	var grid_pos = snap_to_grid(cursor_mesh.global_transform.origin)
	
	if grid_pos in track_map:
		# Reset track memory if we try to place on an existing track
		last_track = null
		last_track_pos = null
		second_last_track = null
		second_last_track_pos = null
		return  

	var track_scene = get_selected_track_scene()
	var new_track = track_scene.instantiate()
	new_track.global_transform.origin = grid_pos

	if dragging and last_track:
		determine_track_type(grid_pos)
	
	add_child(new_track)
	track_map[grid_pos] = new_track  

	second_last_track = last_track
	second_last_track_pos = last_track_pos
	last_track_pos = grid_pos  
	last_track = new_track  

func determine_track_type(new_pos):
	if second_last_track and last_track:
		var last_diff = last_track_pos - second_last_track_pos
		var new_diff = new_pos - last_track_pos

		# If direction changes, replace last straight track with a curved one
		if last_diff.dot(new_diff) == 0:  
			var curved_track = track_normal_curved.instantiate()
			curved_track.global_transform.origin = last_track_pos
			curved_track.rotation_degrees.y = determine_curve_rotation(last_diff, new_diff)

			last_track.queue_free()
			track_map[last_track_pos] = curved_track
			add_child(curved_track)
			last_track = curved_track
		else:
			var straight_track = track_normal_straight.instantiate()
			straight_track.global_transform.origin = last_track_pos
			straight_track.rotation_degrees.y = determine_straight_rotation(new_diff)

			last_track.queue_free()
			track_map[last_track_pos] = straight_track
			add_child(straight_track)
			last_track = straight_track

func determine_straight_rotation(new_diff):
	if new_diff.x > 0:
		return 90
	elif new_diff.x < 0:
		return 270
	elif new_diff.z > 0:
		return 0
	elif new_diff.z < 0:
		return 180
	return 0  

func determine_curve_rotation(last_diff, new_diff):
	if last_diff.x > 0:
		return 180 if new_diff.z > 0 else 90
	if last_diff.x < 0:
		return 270 if new_diff.z > 0 else 0
	if last_diff.z > 0:
		return 0 if new_diff.x > 0 else 90
	if last_diff.z < 0:
		return 270 if new_diff.x > 0 else 180
	return 0

func remove_track():
	var grid_pos = snap_to_grid(cursor_mesh.global_transform.origin)
	if grid_pos in track_map:
		var track_to_remove = track_map[grid_pos]
		if track_to_remove:
			track_to_remove.queue_free()
			track_map.erase(grid_pos)
			if last_track_pos == grid_pos:
				last_track_pos = null
				last_track = null

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
	if preview_track:
		preview_track.visible = is_valid

func is_placeable(position):
	return not track_map.has(position)  

func get_selected_track_scene():
	if selected_material == "normal":
		return track_normal_straight  
	else:
		return track_golden_straight  

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
