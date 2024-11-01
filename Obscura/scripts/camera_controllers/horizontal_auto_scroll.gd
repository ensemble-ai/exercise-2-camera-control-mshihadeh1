class_name HorizontalAutoScroll
extends CameraControllerBase

@export var top_left: Vector2 = Vector2(-5, 5)
@export var bottom_right: Vector2 = Vector2(5, -5)
@export var autoscroll_speed: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if target:
		global_position = Vector3(target.global_position.x, 30, target.global_position.z)

# Called every frame to update the camera's position.
func _process(delta: float) -> void:
	if !target:
		return

	# Auto-scroll logic
	global_position.x += autoscroll_speed * delta

	# Ensure target is within frame and push if necessary
	var tpos = target.global_position
	var left_edge = global_position.x + top_left.x
	var right_edge = global_position.x + bottom_right.x
	var top_edge = global_position.z + top_left.y
	var bottom_edge = global_position.z + bottom_right.y

	if tpos.x < left_edge:
		tpos.x = left_edge  # Push the player forward if lagging behind
	elif tpos.x > right_edge:
		tpos.x = right_edge  # Keep the player inside the right edge

	if tpos.z > top_edge:
		tpos.z = top_edge  # Keep the player inside the top edge
	elif tpos.z < bottom_edge:
		tpos.z = bottom_edge  # Keep the player inside the bottom edge

	target.global_position = tpos

	if draw_camera_logic:
		draw_logic()

# Function called to update the visual representation of the camera logic.
func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	var box_width:float = abs(top_left.x) + abs(bottom_right.x) 
	var box_height:float = abs(top_left.y) + abs(bottom_right.y)
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left:float = -box_width / 2
	var right:float = box_width / 2
	var top:float = -box_height / 2
	var bottom:float = box_height / 2
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
