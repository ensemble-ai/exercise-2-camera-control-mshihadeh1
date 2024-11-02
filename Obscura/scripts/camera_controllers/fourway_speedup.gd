class_name FourWayPushZoneCamera
extends CameraControllerBase

@export var push_ratio: float = 0.5
@export var pushbox_top_left: Vector2 = Vector2(-5, 5)
@export var pushbox_bottom_right: Vector2 = Vector2(5, -5)
@export var speedup_zone_top_left: Vector2 = Vector2(-2.5, 2.5)
@export var speedup_zone_bottom_right: Vector2 = Vector2(2.5, -2.5)
@export var box_width:float = 10.0
@export var box_height:float = 10.0

var previous_target_position: Vector3 = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if target:
		global_position = Vector3(target.global_position.x, 30, target.global_position.z)
		previous_target_position = target.global_position

# Called every frame to update the camera's position.
func _process(delta: float) -> void:
	if !target:
		return

	var target_position = target.global_position
	var target_speed = (target_position - previous_target_position).length() / delta
	if target_speed < 0.01:
		target_speed = 0
	var camera_move = Vector3(0, 0, 0)

	var left_edge = target_position.x + pushbox_top_left.x
	var right_edge = target_position.x + pushbox_bottom_right.x
	var top_edge = target_position.z + pushbox_top_left.y
	var bottom_edge = target_position.z + pushbox_bottom_right.y

	var left_inner = global_position.x + speedup_zone_top_left.x
	var right_inner = global_position.x + speedup_zone_bottom_right.x
	var top_inner = global_position.z + speedup_zone_top_left.y
	var bottom_inner = global_position.z + speedup_zone_bottom_right.y

	# Check if target is outside speedup zone but within the pushbox
	if (target_position.x < left_inner or target_position.x > right_inner or target_position.z < bottom_inner or target_position.z > top_inner) and (target_position.x > left_edge and target_position.x < right_edge and target_position.z > bottom_edge and target_position.z < top_edge):
		
		var push_x = target_speed if target_position.x > left_inner and target_position.x < right_inner else push_ratio * target_speed
		var push_z = target_speed if target_position.z > bottom_inner and target_position.z < top_inner else push_ratio * target_speed
		camera_move = Vector3(push_x, 0, push_z)
	
	# If target is at the edge of the pushbox, move at full speed in that direction
	if target_position.x <= left_edge or target_position.x >= right_edge:
		camera_move.x = target_speed
	if target_position.z <= bottom_edge or target_position.z >= top_edge:
		camera_move.z = target_speed

	global_position = global_position.lerp(Vector3(clamp(target_position.x, left_edge + box_width / 2, right_edge - box_width / 2), 30, clamp(target_position.z, bottom_edge + box_height / 2, top_edge - box_height / 2)), 0.2 * delta)
	
	previous_target_position = target_position

	if draw_camera_logic:
		draw_logic()

# Function called to update the visual representation of the push zone.
func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	var box_width: float = abs(pushbox_bottom_right.x - pushbox_top_left.x) 
	var box_height: float = abs(pushbox_top_left.y - pushbox_bottom_right.y)
	
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
	mesh_instance.global_transform.origin = Vector3(global_position.x, 30, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
