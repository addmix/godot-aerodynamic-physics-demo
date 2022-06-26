extends AeroBody3D

var throttle : float = 0.0
var throttle_speed : float = 0.5
var engine_enabled : bool = false

@export var thrust_force : float = 1700.0

@export var pitch_vectoring : bool = true
@export var yaw_vectoring : bool = true
@export var roll_vectoring : bool = true
@export var vector_speed : Vector3 = Vector3(1.0, 1.0, 1.0)
@export var vector_authority : Vector3 = Vector3(45.0, 45.0, 45.0)

@onready var thrust_position : Node3D = $ThrustPosition as Node3D

@onready var ui : Control = $UI

@export var pitch_control : bool = true
@export var yaw_control : bool = true
@export var roll_control : bool = true
@export var control_speed : Vector3 = Vector3(1.0, 1.0, 1.0)
@export var control_authority : Vector3 = Vector3(45.0, 45.0, 45.0)

@onready var Rudder : AeroSurface3D = $Rudder as AeroSurface3D
@onready var ElevatorR : AeroSurface3D = $ElevatorR as AeroSurface3D
@onready var ElevatorL : AeroSurface3D = $ElevatorL as AeroSurface3D
@onready var AileronL : AeroSurface3D = $AileronL as AeroSurface3D
@onready var AileronR : AeroSurface3D = $AileronR as AeroSurface3D
@onready var MainL : AeroSurface3D = $MainL as AeroSurface3D
@onready var MainR : AeroSurface3D = $MainR as AeroSurface3D

@onready var OrbitCam : Node3D = $OrbitCam

@export var braking_force : float = 10.0
var brakes : float = 0.0
@export var braking_speed : float = 0.5

@export var steering_authority : float = 45.0
@export var steering_speed : float = 0.1
@onready var FrontWheel : VehicleWheel3D = $FrontWheel

var body_state : PhysicsDirectBodyState3D

var last_velocity : Vector3 = Vector3.ZERO

func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	body_state = state
	apply_force(-thrust_position.global_transform.basis.z * thrust_force * throttle * float(engine_enabled), transform.basis * thrust_position.transform.origin)
	super._integrate_forces(state)
	ui.set_physics_process(true)

func _physics_process(delta : float) -> void:
	var increase_throttle : bool = Input.is_action_pressed("throttle_increase")
	if increase_throttle or Input.is_action_pressed("throttle_decrease"):
		throttle = clamp(MathUtils.move_to(delta, throttle, float(increase_throttle), throttle_speed), 0.0, 1.0)
		ui.throttle = throttle
	
	#take input
	var pitch : float = Input.get_axis("pitch_down", "pitch_up")
	var yaw : float = Input.get_axis("yaw_left", "yaw_right")
	var roll : float = Input.get_axis("roll_left", "roll_right")
	
	thrust_position.rotation.x = MathUtils.move_to(delta, thrust_position.rotation.x, pitch * float(pitch_vectoring) * deg2rad(vector_authority.x), vector_speed.x)
	thrust_position.rotation.y = MathUtils.move_to(delta, thrust_position.rotation.y, -yaw * float(yaw_vectoring) * deg2rad(vector_authority.y), vector_speed.y)
	
	ElevatorL.flap_angle = MathUtils.move_to(delta, ElevatorL.flap_angle, pitch * float(pitch_control) * deg2rad(control_authority.x), control_speed.x)
	ElevatorR.flap_angle = MathUtils.move_to(delta, ElevatorR.flap_angle, pitch * float(pitch_control) * deg2rad(control_authority.x), control_speed.x)
	Rudder.flap_angle = MathUtils.move_to(delta, Rudder.flap_angle, yaw * float(yaw_control) * deg2rad(control_authority.y), control_speed.y)
	AileronL.flap_angle = MathUtils.move_to(delta, AileronL.flap_angle, -roll * float(roll_control) * deg2rad(control_authority.z), control_speed.z)
	AileronR.flap_angle = MathUtils.move_to(delta, AileronR.flap_angle, roll * float(roll_control) * deg2rad(control_authority.z), control_speed.z)
	
	var braking : bool = Input.is_action_pressed("brakes")
	brakes = MathUtils.move_to(delta, brakes, float(braking), braking_speed)
	
	FrontWheel.brake = brakes * braking_force
	
	steering = MathUtils.move_to(delta, steering, -yaw * deg2rad(steering_authority), steering_speed)
	
	call_deferred("set_last_velocity", linear_velocity)

func set_last_velocity(velocity : Vector3) -> void:
	last_velocity = linear_velocity

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("toggle_engine", false):
		engine_enabled = !engine_enabled
		ui.engine_enabled = engine_enabled

func get_altitude() -> float:
	return global_transform.origin.y * 3.28084

func get_speed() -> float:
	return linear_velocity.length()

func get_local_velocity() -> Vector3:
	return global_transform.basis.inverse() * linear_velocity

func get_angle_of_attack() -> float:
	var angle_of_attack : float = 0.0
	var air_velocity : Vector3 = get_local_velocity()
	return -atan2(air_velocity.y, -air_velocity.z)

func get_g() -> float:
	var delta_velocity : Vector3 = linear_velocity - last_velocity
	var delta_velocity_per_second : Vector3 = (delta_velocity / get_physics_process_delta_time() - body_state.total_gravity) * 0.10197162129779283
	delta_velocity_per_second = global_transform.basis.inverse() * delta_velocity_per_second
	return delta_velocity_per_second.length() * sign(delta_velocity_per_second.y)
