class_name PositionLockLerp
extends CameraControllerBase

@export var follow_speed: float = 0.01
@export var catchup_speed: float = 0.01
@export var leash_distance: float = 25
@export var cross_size: float = 2.5
var previous_target_position: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if target:
		global_position = Vector3(target.global_position.x, 30, target.global_position.z)

# Called every frame to update the camera's position.
func _process(delta: float) -> void:
	if !target:
		return
	
	# Calculating target speed and distance:
	var target_speed: float = target.global_position.distance_to(previous_target_position) / (delta) 
	previous_target_position = target.global_position
	var distance_to_target = Vector3(global_position.x, 0, global_position.z).distance_to(Vector3(target.global_position.x, 0, target.global_position.z))
	
	# Initialize working speed
	var follow_speed_current = follow_speed

	# If the distance is greater than leash distance, snap to location 
	if distance_to_target > leash_distance:
		follow_speed_current = (1/delta) 
	# If Target Speed < 1 use Catchup Speed; Else use Follow Speed
	if target_speed < 1:
		global_position = global_position.lerp(Vector3(target.global_position.x, global_position.y, target.global_position.z), catchup_speed * delta)
	else:
		global_position = global_position.lerp(Vector3(target.global_position.x, global_position.y, target.global_position.z), follow_speed_current * delta)

	if draw_camera_logic:
		draw_logic()

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
