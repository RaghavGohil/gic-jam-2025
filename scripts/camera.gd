extends Camera3D

@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 50.0
@export var pan_speed: float = 0.1

var is_panning: bool = false
var last_mouse_position: Vector2

func _input(event):
	# Scroll to Zoom (Changes Y-axis height)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			position.y = max(min_zoom, position.y - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			position.y = min(max_zoom, position.y + zoom_speed)

		# Start/Stop Panning with Middle Mouse Button
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			last_mouse_position = event.position

	# Move (Pan) on X and Z axes while holding the middle mouse button
	elif event is InputEventMouseMotion and is_panning:
		var delta_mouse = (event.position - last_mouse_position) * pan_speed
		translate(Vector3(-delta_mouse.x, delta_mouse.y, 0))  # X and Z movement
		last_mouse_position = event.position
