extends Control

var throttle : float = 0.0 setget set_throttle
var engine_enabled : bool = false setget set_engine_enabled

onready var throttle_ui : TextureProgress = $Throttle
onready var ias_ui : Label = $V/IAS
onready var altimeter_ui : Label = $V/Altimeter
onready var mach_ui : Label = $V/Mach
onready var alpha_ui : Label = $V/Alpha
onready var g_ui : Label = $V/G

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta : float) -> void:
	_update_ui()

func _update_ui() -> void:
	var speed : float = get_parent().get_speed()
	
	ias_ui.text = "IAS %s knots" % str(stepify(speed * 1.943844, 0.1))
	altimeter_ui.text = "%s ft" % str(int(round(get_parent().get_altitude() * 3.28084)))
	mach_ui.text = "M: %s" % str(stepify(speed * 0.002938670, 0.01))
	alpha_ui.text = "a: %s" % str(round(rad2deg(get_parent().get_angle_of_attack())))
	g_ui.text = "G: %s" % str(stepify(get_parent().get_g(), 0.1))

func set_throttle(value : float) -> void:
	throttle = value
	throttle_ui.value = value

func set_engine_enabled(value : bool) -> void:
	engine_enabled = value
	throttle_ui.visible = value
