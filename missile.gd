extends AeroBody

#aim-9

#weight 85kg
#length 3m
#diameter 0.127m
#fin span 0.444m
#wingspan 0.353m
#capable of carrying 9.36kg annular blast ragmentation warhead to a range of more than 10 miles




#i might just need to use a simplified aerodynamic model, difficult to calculate necessary controls




onready var ThrustPosition : Position3D = $ThrustPosition as Position3D
onready var target : VehicleBody = get_node("../Target")

onready var desired_direction : Vector3 = -global_transform.basis.z
onready var delta_velocity : Vector3 = desired_direction
var control_auth : Vector3 = Vector3(0, 0, 0)
export var control_speed : float = 7.0

onready var left : AeroSurface = $LeftFront
onready var right : AeroSurface = $RightFront
onready var top : AeroSurface = $DorsalFront
onready var bottom : AeroSurface = $VentralFront

func _physics_process(delta : float) -> void:
	control_auth = Vector3.ZERO
	relative_target_velocity = target.linear_velocity - linear_velocity
	
	#update los
	los = get_los()
	last_los = get_last_los()
	#thrust
	apply_impulse(-global_transform.basis.xform(ThrustPosition.transform.origin), -global_transform.basis.z * 800 * delta)
	
	#control
#	control_auth = Vector3(Input.get_axis("yaw_left", "yaw_right"), Input.get_axis("pitch_down", "pitch_up"), Input.get_axis("roll_left", "roll_right"))
	control_auth += get_pn_control(linear_velocity, angular_velocity)
	
	left.flap_angle = move_to(delta, left.flap_angle, -control_auth.y - control_auth.z * deg2rad(50.0), control_speed)
	right.flap_angle = move_to(delta, right.flap_angle, -control_auth.y + control_auth.z * deg2rad(50.0), control_speed)
	top.flap_angle = move_to(delta, top.flap_angle, -control_auth.x - control_auth.z * deg2rad(50.0), control_speed)
	bottom.flap_angle = move_to(delta, bottom.flap_angle, -control_auth.x + control_auth.z * deg2rad(50.0), control_speed)
	
	last_relative_target_velocity = target.linear_velocity - linear_velocity
	last_position = global_transform.origin
	last_target_position = target.global_transform.origin

func get_pn_control(vel : Vector3, ang_vel : Vector3) -> Vector3:
	var local_angular_velocity : Vector3 = global_transform.basis.xform_inv(ang_vel)
	var local_velocity : Vector3 = global_transform.basis.xform_inv(linear_velocity)
	
	var tpn := apn()
	var desired_velocity_change := Vector3(-tpn.x, -tpn.y, -local_angular_velocity.z)
	var desired_velocity : Vector3 = local_velocity + desired_velocity_change
	#angle to desired velocity
	var desired_angle := Vector2(atan2(desired_velocity.x, -desired_velocity.z), atan2(desired_velocity.y, -desired_velocity.z))
	
	var control := Vector3(desired_velocity_change.x, desired_velocity_change.y, 0.0) * 0.005
#	print(control)
	return control

onready var last_target_position : Vector3 = target.global_transform.origin
onready var last_position : Vector3 = global_transform.origin
onready var last_los : Vector2 = get_last_los()
onready var los : Vector2 = get_los()
#no issues
func get_los() -> Vector2:
	var target_relative_position : Vector3 = target.global_transform.origin - global_transform.origin
	var missile_los : Vector3 = global_transform.basis.xform_inv(target_relative_position)
	var missile_los_degrees := Vector2(atan2(missile_los.x, -missile_los.z), atan2(missile_los.y, -missile_los.z))
	return missile_los_degrees

func get_last_los() -> Vector2:
	var target_relative_position : Vector3 = last_target_position - last_position
	var missile_los : Vector3 = global_transform.basis.xform_inv(target_relative_position)
	var missile_los_degrees := Vector2(atan2(missile_los.x, -missile_los.z), atan2(missile_los.y, -missile_los.z))
	return missile_los_degrees

onready var relative_target_velocity : Vector3 = target.linear_velocity - linear_velocity
onready var last_relative_target_velocity : Vector3 = target.linear_velocity - linear_velocity
func tpn() -> Vector2:
	var closing_velocity : float = global_transform.basis.xform_inv(relative_target_velocity).length()
	var los_rate : Vector2 = (last_los - los) / get_physics_process_delta_time()
	
	return Physics3DUtils.tpn(3.0, closing_velocity, los_rate)

func apn() -> Vector2:
	var closing_velocity : float = global_transform.basis.xform_inv(relative_target_velocity).length()
	var los_rate : Vector2 = (last_los - los) / get_physics_process_delta_time()
	
	#getting line of sight
	var target_relative_position : Vector3 = target.global_transform.origin - global_transform.origin
	var missile_los : Vector3 = global_transform.basis.xform_inv(target_relative_position).normalized()
	#acceleration viewed by missile
	var target_acceleration : Vector3 = (last_relative_target_velocity - relative_target_velocity) / get_physics_process_delta_time()
	#acceleration amount normal to los
	var target_normal_acceleration : float = missile_los.normalized().dot(target_acceleration)
	
	
	return Physics3DUtils.apn(3.0, closing_velocity, los_rate, target_normal_acceleration, los - last_los)





static func move_to(delta : float, position : float, target : float, speed : float = 1.0) -> float:
	var direction : float = sign(target - position)
	var new_position = position + direction * speed * delta
	var new_direction : float = sign(target - new_position)
	
	return float_toggle(direction == new_direction, new_position, target)

static func float_toggle(condition : bool, _true : float, _false : float) -> float:
	return float(condition) * _true + float(!condition) * _false

static func bias(x : float, bias : float) -> float:
	var f : float = 1 - bias
	var k : float = f * f * f
	return (x * k) / (x * k - x + 1.0)
