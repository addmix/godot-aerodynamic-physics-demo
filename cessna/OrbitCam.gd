extends Spatial

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.x = clamp(rotation_degrees.x - event.relative.y * 0.3, -90, 90)
		rotation_degrees.y -= event.relative.x * 0.3
