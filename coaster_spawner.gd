extends Node3D

@export var coaster_scene: PackedScene  # Assign the coaster scene in the Inspector
@export var min_train_length: int = 2  # Minimum number of coasters
@export var max_train_length: int = 6  # Maximum number of coasters
@export var grid_size: float = 5.0  # Grid spacing metric
@export var spawn_height: float = 1.0  # Height of spawned coasters

# Define a set of colors for coasters
@export var coaster_colors: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.ORANGE, Color.PURPLE
]

# Possible movement directions
var DIRECTIONS = [
	Vector3.FORWARD, Vector3.BACK,  # Up, Down
	Vector3.LEFT, Vector3.RIGHT  # Left, Right
]

func _ready() -> void:
	spawn_coasters()

func spawn_coasters():
	if coaster_scene == null:
		print("No coaster scene assigned!")
		return

	var train_length = randi_range(min_train_length, max_train_length)  # Random train length
	var start_position = global_transform.origin  # Starting position of the train
	
	print("Spawning a train with", train_length, "coasters")

	# Choose a random movement pattern
	var pattern = _choose_spawn_pattern(train_length)

	var current_position = start_position  # Initialize position

	for i in range(train_length):
		var coaster = coaster_scene.instantiate()
		var direction = pattern[i]  # Direction for this coaster
		current_position += direction * grid_size  # Move position based on direction

		coaster.global_transform.origin = current_position
		coaster.transform.basis = _calculate_rotation(direction)  # Rotate properly
		add_child(coaster)  # Add to scene

		# Assign a unique color
		var color_index = i % coaster_colors.size()
		_assign_color(coaster, coaster_colors[color_index])

		print("Spawned coaster at:", current_position, "Direction:", direction, "Color:", coaster_colors[color_index])

# Function to assign color to coaster's material
func _assign_color(coaster: Node3D, color: Color):
	var coaster_mesh = coaster.get_child(0)
	if coaster_mesh is MeshInstance3D:
		var material = coaster_mesh.get_surface_override_material(0)
		if material == null:
			material = StandardMaterial3D.new()
			coaster_mesh.set_surface_override_material(0, material)
		material.albedo_color = color
	elif coaster.has_node("MeshInstance3D"):  # If the coaster has a mesh child
		var mesh_instance = coaster.get_node("MeshInstance3D")
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		mesh_instance.set_surface_override_material(0, material)

# Function to determine train shape (Straight-line or L-shape in any direction)
func _choose_spawn_pattern(train_length: int) -> Array[Vector3]:
	var pattern : Array[Vector3] = []
	var is_l_shape = randi() % 2 == 0  # 50% chance of L-shape

	# Pick a random starting direction
	var straight_dir = DIRECTIONS[randi() % DIRECTIONS.size()]
	var turn_dir = _choose_turn_direction(straight_dir)  # Get a valid turn

	if is_l_shape and train_length > 2:
		# First half in one direction, second half turns
		for i in range(train_length):
			if i < train_length / 2:
				pattern.append(straight_dir)
			else:
				pattern.append(turn_dir)
	else:
		# Straight line
		for i in range(train_length):
			pattern.append(straight_dir)

	return pattern

# Function to choose a valid turn direction for L-shape
func _choose_turn_direction(straight_dir: Vector3) -> Vector3:
	if straight_dir == Vector3.FORWARD or straight_dir == Vector3.BACK:
		return Vector3.LEFT if randi() % 2 == 0 else Vector3.RIGHT
	else:
		return Vector3.FORWARD if randi() % 2 == 0 else Vector3.BACK

# Function to calculate correct rotation based on direction with a 90-degree offset
func _calculate_rotation(direction: Vector3) -> Basis:
	var basis = Basis().looking_at(direction, Vector3.UP)  # Original orientation
	var rotation_offset = Basis(Vector3.UP, deg_to_rad(90))  # 90-degree rotation around UP axis
	return basis * rotation_offset  # Apply the offset
