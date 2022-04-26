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
onready var target : RigidBody = get_node("../Target")

onready var desired_direction : Vector3 = -global_transform.basis.z
onready var delta_velocity : Vector3 = desired_direction
var control_auth : Vector3 = Vector3(0, 0, 0)
export var control_speed : float = 7.0

onready var left : AeroSurface = $LeftFront
onready var right : AeroSurface = $RightFront
onready var top : AeroSurface = $DorsalFront
onready var bottom : AeroSurface = $VentralFront

var control_iterations : int = 4

func _physics_process(delta : float) -> void:
	control_auth = Vector3.ZERO
	#update los
	los = get_los()
	#thrust
	apply_impulse(-global_transform.basis.xform(ThrustPosition.transform.origin), -global_transform.basis.z * 400 * delta)
	
	#control
	control_auth = Vector3(Input.get_axis("yaw_left", "yaw_right"), Input.get_axis("pitch_down", "pitch_up"), Input.get_axis("roll_left", "roll_right"))
	
#	print(get_pn_control(linear_velocity, angular_velocity))
#	control_auth += get_pn_control(linear_velocity, angular_velocity)
#	print(control_auth)
	
	
#	left.flap_angle = move_to(delta, left.flap_angle, control_auth.y * deg2rad(50) + control_auth.z * deg2rad(50), control_speed)
#	right.flap_angle = move_to(delta, right.flap_angle, control_auth.y * deg2rad(50) - control_auth.z * deg2rad(50), control_speed)
#	top.flap_angle = move_to(delta, top.flap_angle, control_auth.x * deg2rad(50) + control_auth.z * deg2rad(50), control_speed)
#	bottom.flap_angle = move_to(delta, bottom.flap_angle, control_auth.x * deg2rad(50) - control_auth.z * deg2rad(50), control_speed)
	left.flap_angle = -control_auth.y - control_auth.z
	right.flap_angle = -control_auth.y + control_auth.z
	top.flap_angle = -control_auth.x - control_auth.z
	bottom.flap_angle = -control_auth.x + control_auth.z
	
	last_los = los

func get_pn_control(vel : Vector3, ang_vel : Vector3) -> Vector3:
	var local_angular_velocity : Vector3 = global_transform.basis.xform_inv(ang_vel)
	var tpn := tpn(vel)
	var desired_velocity_change := Vector3(-tpn.x, -tpn.y, -local_angular_velocity.z)
	
	#figure out what control is necessary for velocity change here
	
	
	
	#brute force? >good for now?
		#on each axis, x,y, start with 3 segments, test outcome of each
		#[-1]---[0]---[1]
		#if control magnitude >1 is necessary on either axis, we can discard solving that axis
		#recursion
			#subdivide section to resemble original, repeat for X substeps, further narrowing down necessary control
	
	
	
	#precompiled data? >similar to training an algorithm, but possibly slower, more difficult
	#formula? >most performant >probably hard to make solver >tricky to inplement myself
		#calculate necessary torque force,
		#reverse lift algorithm?
	#train an algorithm? >good way to gain experience
	
	var control : Vector3 = Vector3(desired_velocity_change.x, desired_velocity_change.y, desired_velocity_change.z)
	
	return control

func tpn(velocity : Vector3) -> Vector2:
	var relative_target_velocity : Vector3 = target.linear_velocity - velocity
	var local_velocity : Vector3 = global_transform.basis.xform_inv(relative_target_velocity)
	var closing_velocity : float = local_velocity.length()
	var los_rate : Vector2 = (last_los - los) / get_physics_process_delta_time()
	return Physics3DUtils.tpn(closing_velocity, los_rate * Vector2(1, 1))

onready var last_los : Vector2 = get_los()
onready var los : Vector2 = get_los()
func get_los() -> Vector2:
	var target_relative_position : Vector3 = target.global_transform.origin - global_transform.origin
	var missile_los : Vector3 = global_transform.basis.xform_inv(target_relative_position)
	var missile_los_degrees := Vector2(atan2(missile_los.x, -missile_los.z), atan2(missile_los.y, -missile_los.z))
	
	return missile_los_degrees



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
