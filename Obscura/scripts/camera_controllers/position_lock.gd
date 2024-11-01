class_name PositionLock
extends CameraControllerBase

@export var cross_size: float = 2.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	if target:
		global_position = target.global_position

# Called every frame to update the camera's position.
func _process(delta: float) -> void:
	if !target:
		return

	global_position = target.global_position  # Keep the camera centered on the Vessel

	if draw_camera_logic:
		draw_logic()
	
	super(delta)

# Function called to update the visual representation of the camera logic.
func draw_logic() -> void:
	var immediate_mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	# Draw horizontal line of the cross
	immediate_mesh.surface_add_vertex(Vector3(-cross_size, 0, 20))
	immediate_mesh.surface_add_vertex(Vector3(cross_size, 0, 20))
	# Draw vertical line of the cross
	immediate_mesh.surface_add_vertex(Vector3(0, -cross_size, 20))
	immediate_mesh.surface_add_vertex(Vector3(0, cross_size, 20))
	immediate_mesh.surface_end()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(mesh_instance)
	mesh_instance.global_transform.origin = Vector3(global_position.x, 0, global_position.z)

	# Mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
