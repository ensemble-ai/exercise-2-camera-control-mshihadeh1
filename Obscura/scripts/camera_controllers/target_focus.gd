class_name TargetFocus
extends CameraControllerBase

@export var lead_speed: float = 300
@export var catchup_delay_duration: float = 0.5
@export var leash_distance: float = 10
@export var catchup_speed: float = 5
@export var cross_size: float = 2.5

var previous_target_position: Vector3
var time_since_last_movement: float = 0

func _ready() -> void:
	if target:
		global_position = Vector3(target.global_position.x, 30, target.global_position.z)
		previous_target_position = target.global_position

func _process(delta: float) -> void:
	if !target:
		return
	
	# Calculate target movement
	var target_position_change: Vector3 = target.global_position - previous_target_position
	
	if target_position_change.length() > 0:
		# Reset timer if target is moving
		time_since_last_movement = 0
		
		# Calculate lead position based on target movement
		var lead_target_position: Vector3 = target.global_position + (target_position_change.normalized() * lead_speed)
		
		# Lerp towards the lead target position with return speed
		var new_position: Vector3 = global_position.lerp(lead_target_position, delta * catchup_speed)
		
		# Clamp the new position to leash distance from target
		var offset = new_position - target.global_position
		if offset.length() > leash_distance:
			offset = offset.normalized() * leash_distance
		new_position = offset + target.global_position

		# Apply the calculated position
		global_position = Vector3(new_position.x, 30, new_position.z)
	else:
		# Check if the target has stopped moving for catchup
		if time_since_last_movement >= catchup_delay_duration:
			var return_position: Vector3 = global_position.lerp(Vector3(target.global_position.x, global_position.y, target.global_position.z), delta * catchup_speed)
			global_position = Vector3(return_position.x, 30, return_position.z)
		
		# Increment idle timer if target is not moving
		time_since_last_movement += delta
	
	# Update previous position for next frame's calculations
	previous_target_position = target.global_position
	
	# Draw cross if enabled
	if draw_camera_logic:
		draw_logic()

# Function to draw a 5x5 unit cross in the center of the camera view
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
