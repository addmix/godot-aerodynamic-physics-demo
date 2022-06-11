extends Spatial

var camera_rotation : Vector3 = Vector3(0.0, 0.0, 0.0)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_rotation.x = deg2rad(clamp(rad2deg(camera_rotation.x) - event.relative.y * 0.3, -90.0, 90.0))
		camera_rotation.y -= deg2rad(event.relative.x * 0.3)

func _process(delta : float) -> void:
	var velocity : Vector3 = get_parent().global_transform.basis.xform_inv(get_parent().linear_velocity)
	
	if get_parent().body_state:
		var length = velocity.length()
		
		var forward : Vector3
		if length < 1.0:
			forward = Vector3(0.0, 0.0, 1.0)
		else:
			var normalized : Vector3 = velocity.normalized()
			forward = -normalized
		
		var up = Vector3(0.0, -1.0, 0.0)
		var right = (forward.cross(up)).normalized()
		up = (forward.cross(right))
		
		var basis = Basis(right, up, forward).orthonormalized()
		basis = Basis(basis.get_rotation_quat()).orthonormalized()
		if transform.basis != basis:
			transform.basis = transform.basis.get_rotation_quat().slerp(basis.get_rotation_quat(), 0.01 * length)# + camera_rotation)
