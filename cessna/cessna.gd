extends AeroBody

export var thrust_force : float = 600.0

onready var Rudder : AeroSurface = $Rudder as AeroSurface
onready var ElevonR : AeroSurface = $ElevonR as AeroSurface
onready var ElevonL : AeroSurface = $ElevonL as AeroSurface
onready var AileronL : AeroSurface = $AileronL as AeroSurface
onready var AileronR : AeroSurface = $AileronR as AeroSurface
onready var MainL : AeroSurface = $MainL as AeroSurface
onready var MainR : AeroSurface = $MainR as AeroSurface

func _physics_process(delta : float) -> void:
	apply_central_impulse(-global_transform.basis.z * thrust_force * delta)
	
	var pitch : float = Input.get_axis("pitch_down", "pitch_up")
	var yaw : float = Input.get_axis("yaw_left", "yaw_right")
	var roll : float = Input.get_axis("roll_left", "roll_right")
	
	ElevonL.flap_angle = move_to(delta, ElevonL.flap_angle, pitch * deg2rad(50.0), 0.2)
	ElevonR.flap_angle = move_to(delta, ElevonR.flap_angle, pitch * deg2rad(50.0), 0.2)
	Rudder.flap_angle = move_to(delta, Rudder.flap_angle, yaw * deg2rad(50.0), 0.7)
	AileronL.flap_angle = move_to(delta, AileronL.flap_angle, -roll * deg2rad(20.0), 0.7)
	AileronR.flap_angle = move_to(delta, AileronR.flap_angle, roll * deg2rad(20.0), 0.7)

static func move_to(delta : float, position : float, target : float, speed : float = 1.0) -> float:
	var direction : float = sign(target - position)
	var new_position = position + direction * speed * delta
	var new_direction : float = sign(target - new_position)
	
	return float_toggle(direction == new_direction, new_position, target)

static func float_toggle(condition : bool, _true : float, _false : float) -> float:
	return float(condition) * _true + float(!condition) * _false
