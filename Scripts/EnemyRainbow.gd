extends Enemy

class_name EnemyRainbow

var pos_on_field_A : Vector2i
var pos_on_field_B : Vector2i
var direction_A : Vector2
var direction_B : Vector2
var mirror_start_pos_A : Vector2i
var mirror_start_pos_B : Vector2i
var mirror_end_pos_A : Vector2i
var mirror_end_pos_B : Vector2i
var speed : float = 100
var max_leash : float = 100
var min_leash : float = 50
var death_spot : Vector2i
var unhandled_A_movement : Vector2
var unhandled_B_movement : Vector2
var max_change_time : float = 10
var min_change_time : float = 1
var countdown_to_change : float = 0

var start_color_hue : float = Color.DARK_VIOLET.h
var end_color_hue : float = Color.AQUAMARINE.h
var color_index : int = 0
var max_shadows : int = 25
var next_shadow_write : float = 0
var shadow_start : Array = []
var shadow_end : Array = []

# REQUIRED
func set_pending_mirror_coordinates() -> void:
	mirror_start_pos_A = pos_on_field_A
	mirror_start_pos_B = pos_on_field_B
	mirror_end_pos_A = play_state.mirror_v2i(pos_on_field_A)
	mirror_end_pos_B = play_state.mirror_v2i(pos_on_field_B)
	direction_A.x *= -1
	direction_B.x *= -1

# REQUIRED
func set_mirror_pos(remaining_fraction : float) -> void:
	pos_on_field_A = Enemy.lerp_v2i(mirror_end_pos_A, mirror_start_pos_A, remaining_fraction)
	pos_on_field_B = Enemy.lerp_v2i(mirror_end_pos_B, mirror_start_pos_B, remaining_fraction)

func chose_new_goal() -> void:
	pass
	
# REQUIRED
func chose_spawn_spot() -> void:
	shadow_start = []
	shadow_end = []
	pos_on_field_A = get_spawn_spot()
	pos_on_field_B = get_spawn_spot()
	direction_A = random_direction()
	direction_B = random_direction()
	unhandled_A_movement = Vector2.ZERO
	unhandled_B_movement = Vector2.ZERO
	var vec_A_to_B : Vector2 = (pos_on_field_B - pos_on_field_A) as Vector2
	var len_A_to_B : float = vec_A_to_B.length()
	var average_leash = (max_leash + min_leash) / 2
	if len_A_to_B > average_leash:
		var move_amount : float = (len_A_to_B - average_leash) / 2
		var move_vector : Vector2i = (vec_A_to_B.normalized() * move_amount) as Vector2i
		pos_on_field_A += move_vector
		pos_on_field_B -= move_vector

# REQUIRED
func get_distance_from_point_squared(pos : Vector2i) -> float:
	if is_alive():
		var dist_to_A : float = (pos - pos_on_field_A).length_squared()
		var dist_to_B : float = (pos - pos_on_field_B).length_squared()
		return min(dist_to_A, dist_to_B)
	else:
		return (500 * 500 + 500 * 500);

# REQUIRED
func get_tutorial_location() -> Vector2i:
	return (pos_on_field_A + pos_on_field_B) / 2

# REQUIRED
func render(offset : Vector2) -> void:
	#var loc : Vector2 = offset + (pos_on_field as Vector2)
	#var radius : float = 3
	if current_enemy_state == EnemyState.TRAPPED:
		play_state.draw_line(offset + (pos_on_field_A as Vector2), offset + (pos_on_field_B as Vector2), Color.BLACK, 0.8)
	elif current_enemy_state == EnemyState.MOVING:
		for i in range(0, shadow_start.size()):
			var n : int = (i + color_index) % shadow_start.size()
			var frac : float = i / float(shadow_start.size() - 1)
			var color : Color = Color.from_hsv(lerp(start_color_hue, end_color_hue, frac), 1, 1)
			play_state.draw_line(offset + (shadow_start[n] as Vector2), offset + (shadow_end[n] as Vector2), color, 0.6)
	elif current_enemy_state == EnemyState.RESPAWNING:
		var fraction : float = 1 - (respawn_remaining / max_respawn_time)
		play_state.draw_line(offset + (pos_on_field_A as Vector2), offset + (pos_on_field_B as Vector2), Color(Color.VIOLET, fraction), 0.6)

# REQUIRED
func get_death_spot() -> Vector2i:
	return death_spot

# REQUIRED
func move_enemy(delta : float) -> void:
	if current_enemy_state != EnemyState.TRAPPED:
		if play_state.is_in_claimed_area(pos_on_field_A.x, pos_on_field_A.y):
			change_state(EnemyState.TRAPPED)
			return
		elif play_state.is_in_claimed_area(pos_on_field_B.x, pos_on_field_B.y):
			change_state(EnemyState.TRAPPED)
			return

	if current_enemy_state == EnemyState.RESPAWNING:
		respawn_remaining -= delta
		if respawn_remaining <= 0:
			change_state(EnemyState.MOVING)
		return

	if current_enemy_state == EnemyState.TRAPPED:
		stun_remaining -= delta
		if stun_remaining <= 0:
			change_state(EnemyState.RESPAWNING)
			play_state.play_enemy_respawn()
		return
	
	countdown_to_change -= delta
	if countdown_to_change <= 0:
		countdown_to_change = rng.randf_range(min_change_time, max_change_time) / speed_mod
		if (pos_on_field_A - play_state.player_pos).length_squared() < (pos_on_field_B - play_state.player_pos).length_squared():
			direction_B = (direction_B + direction_A + random_direction()).normalized()
		else:
			direction_A = (direction_B + direction_A + random_direction()).normalized()
		
	var vec_A2B : Vector2 = (pos_on_field_B as Vector2) - (pos_on_field_A as Vector2)
	var dist : float = vec_A2B.length_squared()
	var adjust : float = 0
	if dist > (max_leash * max_leash):
		adjust = 1
	elif dist < (min_leash * min_leash):
		adjust = -1
	if adjust != 0:
		var vec_A2B_norm : Vector2 = vec_A2B.normalized() * adjust
		direction_A = (direction_A + vec_A2B_norm).normalized()
		direction_B = (direction_B - vec_A2B_norm).normalized()
	
	unhandled_A_movement += direction_A * delta * speed * speed_mod
	unhandled_B_movement += direction_B * delta * speed * speed_mod
	
	var bleed_data_A : Array = bleed_atomic_move(unhandled_A_movement)
	var bleed_data_B : Array = bleed_atomic_move(unhandled_B_movement)
	while bleed_data_A[0] != Vector2i.ZERO || bleed_data_B[0] != Vector2i.ZERO:
		if bleed_data_A[0] != Vector2i.ZERO:
			var new_pos_A : Vector2i = bleed_data_A[0] + pos_on_field_A
			var advance_A : bool = true
			for line in play_state.outer_lines:
				if PlayState.on_line(new_pos_A.x, new_pos_A.y, line[0], line[1]):
					if play_state.is_path_element_on_x_axis(line):
						unhandled_A_movement.x *= -1
						direction_A.x *= -1
						advance_A = false
					else:
						unhandled_A_movement.y *= -1
						direction_A.y *= -1
						advance_A = false
			if advance_A:
				pos_on_field_A = new_pos_A
		if bleed_data_B[0] != Vector2i.ZERO:
			var new_pos_B : Vector2i = bleed_data_B[0] + pos_on_field_B
			var advance_B : bool = true
			for line in play_state.outer_lines:
				if PlayState.on_line(new_pos_B.x, new_pos_B.y, line[0], line[1]):
					if play_state.is_path_element_on_x_axis(line):
						unhandled_B_movement.x *= -1
						direction_B.x *= -1
						advance_B = false
					else:
						unhandled_B_movement.y *= -1
						direction_B.y *= -1
						advance_B = false
			if advance_B:
				pos_on_field_B = new_pos_B
		unhandled_A_movement = bleed_data_A[1]
		unhandled_B_movement = bleed_data_B[1]
		bleed_data_A = bleed_atomic_move(unhandled_A_movement)
		bleed_data_B = bleed_atomic_move(unhandled_B_movement)
	
	if play_state.does_cross_inner_path(pos_on_field_A, pos_on_field_B):
		death_spot = (pos_on_field_A + pos_on_field_B) / 2
		play_state.on_player_death(play_state.CauseOfDeath.HUNTER)
		next_shadow_write = 0
	
	next_shadow_write -= delta
	if next_shadow_write <= 0:
		next_shadow_write = 2.0 / max_shadows
		if shadow_start.size() < max_shadows:
			shadow_start.append(pos_on_field_A)
			shadow_end.append(pos_on_field_B)
			color_index = shadow_start.size() - 1
		else:
			color_index = (1 + color_index) % shadow_start.size()
			shadow_start[color_index] = pos_on_field_A
			shadow_end[color_index] = pos_on_field_B

func random_direction() -> Vector2:
	return Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10)).normalized()

func bleed_atomic_move(unhandled_movement : Vector2) -> Array:
	if abs(unhandled_movement.x) > abs(unhandled_movement.y):
		if unhandled_movement.x >= 1:
			return [Vector2i(1, 0), unhandled_movement - Vector2(1, 0)]
		elif unhandled_movement.x <= -1:
			return [Vector2i(-1, 0), unhandled_movement - Vector2(-1, 0)]
		else:
			return [Vector2i.ZERO, unhandled_movement]
	else:
		if unhandled_movement.y >= 1:
			return [Vector2i(0, 1), unhandled_movement - Vector2(0, 1)]
		elif unhandled_movement.y <= -1:
			return [Vector2i(0, -1), unhandled_movement - Vector2(0, -1)]
		else:
			return [Vector2i.ZERO, unhandled_movement]
