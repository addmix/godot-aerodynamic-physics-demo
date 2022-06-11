extends Control

var throttle : float = 0.0 setget set_throttle
var engine_enabled : bool = false setget set_engine_enabled

onready var throttle_ui : TextureProgress = $Throttle
onready var ias_ui : Label = $V/IAS
onready var altimeter_ui : Label = $V/Altimeter
onready var mach_ui : Label = $V/Mach
onready var alpha_ui : Label = $V/Alpha
onready var g_ui : Label = $V/G

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

var last_velocity : Vector3 = Vector3.ZERO
func _process(delta : float) -> void:
	var speed : float = get_parent().linear_velocity.length()
	ias_ui.text = "IAS %s knots" % str(stepify(speed * 1.943844, 0.1))
	altimeter_ui.text = "%s ft" % str(int(round(get_parent().global_transform.origin.y * 3.28084)))
	mach_ui.text = "M: %s" % str(stepify(speed * 0.002938670, 0.01))
	
	var air_velocity : Vector3 = get_parent().global_transform.basis.xform_inv(get_parent().linear_velocity)
	var angle_of_attack : float = 0.0
	if speed > 2.0:
		 angle_of_attack = atan2(air_velocity.y, -air_velocity.z)
	
	
	
	alpha_ui.text = "a: %s" % str(round(rad2deg(-angle_of_attack)))
	
	if last_velocity != get_parent().linear_velocity:
		var delta_velocity_in_local_space : Vector3 = get_parent().global_transform.basis.xform_inv(get_parent().linear_velocity - last_velocity)
		var delta_velocity_per_second : Vector3 = (delta_velocity_in_local_space / delta + get_parent().body_state.total_gravity) * 0.10197162129779283
		
		g_ui.text = "G: %s" % str(stepify(delta_velocity_per_second.length() * sign(delta_velocity_in_local_space.y), 0.1))
	
	last_velocity = get_parent().linear_velocity

func set_throttle(value : float) -> void:
	throttle = value
	throttle_ui.value = value

func set_engine_enabled(value : bool) -> void:
	engine_enabled = value
	throttle_ui.visible = value
