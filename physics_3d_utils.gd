class_name Physics3DUtils

#returns the necessary change in velocity to intercept, normal to the instantaneous velocity difference
static func prop_nav_velocity_vector(position : Vector3, velocity : Vector3, target_position : Vector3, target_velocity : Vector3, proportionality_constant : float = 4.0) -> Vector3:
	var relative_target_velocity : Vector3 = target_velocity - velocity
	var relative_range : Vector3 = target_position - position
	var o : Vector3 = (relative_range.cross(relative_target_velocity)) / relative_range.length_squared()
	
	return (proportionality_constant * relative_target_velocity).cross(o)

#returns the necessary change in velocity to intercept, normal to the instantaneous line of sight
static func prop_nav_los_vector(position : Vector3, velocity : Vector3, target_position : Vector3, target_velocity : Vector3, proportionality_constant : float = 4.0) -> Vector3:
	var relative_target_velocity : Vector3 = target_velocity - velocity
	var relative_range : Vector3 = target_position - position
	var o : Vector3 = (relative_range.cross(relative_target_velocity)) / relative_range.length_squared()
	
	return (-proportionality_constant * relative_target_velocity.length() * relative_range.normalized()).cross(o)

#returns the necessary change in velocity to intercept, normal to the instantaneous line of sight
static func prop_nav_conserve_energy_vector(position : Vector3, velocity : Vector3, target_position : Vector3, target_velocity : Vector3, proportionality_constant : float = 4.0) -> Vector3:
	var relative_target_velocity : Vector3 = target_velocity - velocity
	var relative_range : Vector3 = target_position - position
	var o : Vector3 = (relative_range.cross(relative_target_velocity)) / relative_range.length_squared()
	
	return (-proportionality_constant * relative_target_velocity.length() * velocity.normalized()).cross(o)

static func tpn(proportionality_constant : float, closing_velocity : float, los_rate : Vector2) -> Vector2:
	var nsc : float = proportionality_constant * closing_velocity
	return Vector2(nsc * los_rate.x, nsc * los_rate.y)

static func apn(proportionality_constant : float, closing_velocity : float, los_rate : Vector2, normal_acceleration : float) -> Vector2:
	var tpn := tpn(proportionality_constant, closing_velocity, los_rate)
	var d : float = (proportionality_constant * normal_acceleration) / 2.0
	
	return Vector2(tpn.x + d, tpn.y + d)


static func augmented_prop_nav(closing_velocity : float, los_rate : Vector2, los_normal_acceleration : float) -> Vector2:
	var nsc : float = 3.0 * closing_velocity
	var half_n : float = 1.5
	return Vector2(nsc * los_rate.x + half_n * los_normal_acceleration, nsc * los_rate.y + half_n * los_normal_acceleration)
