extends AeroBody

#aim-9

#weight 85kg
#length 3m
#diameter 0.127m
#fin span 0.444m
#wingspan 0.353m
#capable of carrying 9.36kg annular blast ragmentation warhead to a range of more than 10 miles

onready var ThrustPosition : Position3D = $ThrustPosition as Position3D
onready var target : RigidBody = get_node("../Target")

onready var desired_direction : Vector3 = -global_transform.basis.z
onready var delta_velocity : Vector3 = desired_direction
var control_auth : Vector3 = Vector3(0, 0, 0)
export var control_speed : float = 7.0

onready var left : AeroSurface = $LeftFront
onready var right : AeroSurface = $RightFront
onready var top : AeroSurface = $DorsalFront
onready var bottom : AeroSurface = $VentralFront

func _physics_process(delta : float) -> void:
	#thrust
	apply_impulse(-global_transform.basis.xform(ThrustPosition.transform.origin), -global_transform.basis.z * 400 * delta)
	
	#control
#	control_auth = Vector3(Input.get_axis("yaw_right", "yaw_left"), Input.get_axis("pitch_up", "pitch_down"), Input.get_axis("roll_right", "roll_left"))
	
	#work this into desired velocity change
	#
	var local_angular_velocity : Vector3 = global_transform.basis.xform_inv(angular_velocity)
	var roll_correction_proportional_speed : float = 0.2
	var desired_roll_velocity_change : float = -local_angular_velocity.z - rotation.z * roll_correction_proportional_speed
	
	var distance_falloff : float = 500
	var c : float = pow(distance_falloff, -1.0)
	var tpn := tpn()
	var desired_velocity_change := Vector3(tpn.x, tpn.y, desired_roll_velocity_change) * deg2rad(1.0) * 0.02
	
	#figure out what control is necessary for velocity change
	
	control_auth += Vector3(bias(desired_velocity_change.x, 0.2), bias(desired_velocity_change.y, 0.2), 0.0)
	control_auth = control_auth.normalized() * clamp(control_auth.length(), 0, 1)
	
	#move flaps
	left.flap_angle = move_to(delta, left.flap_angle, control_auth.y * deg2rad(50) + control_auth.z * deg2rad(50), control_speed)
	right.flap_angle = move_to(delta, right.flap_angle, control_auth.y * deg2rad(50) - control_auth.z * deg2rad(50), control_speed)
	top.flap_angle = move_to(delta, top.flap_angle, control_auth.x * deg2rad(50) + control_auth.z * deg2rad(50), control_speed)
	bottom.flap_angle = move_to(delta, bottom.flap_angle, control_auth.x * deg2rad(50) - control_auth.z * deg2rad(50), control_speed)

#	left.flap_angle = control_auth.y + control_auth.z
#	right.flap_angle = control_auth.y - control_auth.z
#	top.flap_angle = control_auth.x + control_auth.z
#	bottom.flap_angle = control_auth.x - control_auth.z

func proportional_navigation() -> void:
	delta_velocity = global_transform.basis.xform_inv(Physics3DUtils.prop_nav_velocity(global_transform.origin, linear_velocity, target.global_transform.origin, target.linear_velocity, 3.0))
	desired_direction = delta_velocity.normalized()

onready var last_los : Vector2 = get_los()
func get_los() -> Vector2:
	var target_relative_position : Vector3 = target.global_transform.origin - global_transform.origin
	var missile_los : Vector3 = global_transform.basis.xform_inv(target_relative_position)
	var local_velocity : Vector3 = global_transform.basis.xform_inv(linear_velocity)
	#angle to missile
	var missile_los_degrees := Vector2(atan2(missile_los.x, -missile_los.z), atan2(missile_los.y, -missile_los.z))
	#angle to velocity
	var local_velocity_degrees := Vector2(atan2(local_velocity.x, -local_velocity.z), atan2(local_velocity.y, -local_velocity.z))
	#velocity vector angle to target
	return missile_los_degrees + local_velocity_degrees

func tpn() -> Vector2:
	var relative_target_velocity : Vector3 = target.linear_velocity - linear_velocity
	var local_velocity : Vector3 = global_transform.basis.xform_inv(relative_target_velocity)
	var closing_velocity : float = local_velocity.length()
	
	var los := get_los()
	var los_rate : Vector2 = (last_los - los) / get_physics_process_delta_time()
	
	last_los = los
	return Physics3DUtils.tpn(closing_velocity, los_rate * Vector2(1, 1))


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
	
#	var g : float = (x * k) / (x * k - x + 1.0)
#	print(sign(x) == sign(g))
	return (x * k) / (x * k - x + 1.0)
