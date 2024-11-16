extends Fuze

class_name FuzePair

var pos_on_field_A : Vector2i
var pos_on_field_B : Vector2i
var mirror_start_pos_A : Vector2i
var mirror_start_pos_B : Vector2i
var mirror_end_pos_A : Vector2i
var mirror_end_pos_B : Vector2i
var respawn_remaining_A : float
var respawn_remaining_B : float
var current_state_A : FuzeState
var current_state_B : FuzeState
var move_buffer_A : float = 0
var move_buffer_B : float = 0

func set_pending_mirror_coordinates() -> void:
	mirror_start_pos_A = pos_on_field_A
	mirror_start_pos_B = pos_on_field_B
	mirror_end_pos_A = play_state.mirror_v2i(pos_on_field_A)
	mirror_end_pos_B = play_state.mirror_v2i(pos_on_field_B)

func set_mirror_pos(remaining_fraction : float) -> void:
	pos_on_field_A = Enemy.lerp_v2i(mirror_end_pos_A, mirror_start_pos_A, remaining_fraction)
	pos_on_field_B = Enemy.lerp_v2i(mirror_end_pos_B, mirror_start_pos_B, remaining_fraction)

func init_all_agents() -> void:
	change_state_A(FuzeState.RESPAWNING)
	change_state_B(FuzeState.RESPAWNING)

func change_state_A(new_state : FuzeState) -> void:
	if new_state == FuzeState.RESPAWNING:
		current_state_A = FuzeState.RESPAWNING
		move_buffer_A = 0
		pos_on_field_A = play_state.point_opposite_player()
		respawn_remaining_A = max_respawn_time * 5.0 / (5.0 + difficulty_tier)
	else:
		current_state_A = FuzeState.MOVING

func change_state_B(new_state : FuzeState) -> void:
	if new_state == FuzeState.RESPAWNING:
		current_state_B = FuzeState.RESPAWNING
		move_buffer_B = 0
		pos_on_field_B = play_state.point_opposite_player()
		respawn_remaining_B = max_respawn_time * 5.0 / (5.0 + difficulty_tier)
	else:
		current_state_B = FuzeState.MOVING

func move_all_agents(delta : float) -> void:
	if current_state_A == FuzeState.RESPAWNING:
		respawn_remaining_A -= delta
		if respawn_remaining_A < 0:
			change_state_A(FuzeState.MOVING)
	else:
		move_buffer_A += delta * speed * speed_mod
		while move_buffer_A >= 1:
			move_buffer_A -= 1
			pos_on_field_A = get_new_pos(pos_on_field_A, 1)
			if pos_on_field_A == Vector2i.MAX:
				change_state_A(FuzeState.RESPAWNING)
				play_state.play_fuze_respawn()
			elif current_state_A == FuzeState.RESPAWNING:
				play_state.play_fuze_respawn()
			elif pos_on_field_A == play_state.player_pos:
				play_state.on_player_death()

	if current_state_B == FuzeState.RESPAWNING:
		respawn_remaining_B -= delta
		if respawn_remaining_B < 0:
			change_state_B(FuzeState.MOVING)
	else:
		move_buffer_B += delta * speed * speed_mod
		while move_buffer_B >= 1:
			move_buffer_B -= 1
			pos_on_field_B = get_new_pos(pos_on_field_B, -1)
			if pos_on_field_B == Vector2i.MAX:
				change_state_B(FuzeState.RESPAWNING)
				play_state.play_fuze_respawn()
			elif current_state_B == FuzeState.RESPAWNING:
				play_state.play_fuze_respawn()
			elif pos_on_field_B == play_state.player_pos:
				play_state.on_player_death()

func is_this_location_death(x : int, y : int) -> bool:
	if x == pos_on_field_A.x && y == pos_on_field_A.y:
		return true
	if x == pos_on_field_B.x && y == pos_on_field_B.y:
		return true
	return false
	
func render(offset : Vector2) -> void:
	render_unit(offset, pos_on_field_A, current_state_A, respawn_remaining_A)
	render_unit(offset, pos_on_field_B, current_state_B, respawn_remaining_B)

func render_unit(offset : Vector2, field_pos : Vector2, current_state : FuzeState, respawn_remaining : float):
	var opp : Vector2 = offset + (field_pos as Vector2)
	var spine_count : int = 3
	if current_state == FuzeState.RESPAWNING:
		spine_count *= 3
	for spine in range(0, spine_count):
		var dir = Vector2(cos(rotate + spine), sin(rotate + spine))
		if current_state == FuzeState.RESPAWNING:
			var out_spin : float = 25.0 * respawn_remaining / max_respawn_time
			var vfx_length : float = 6 + (4 * respawn_remaining / max_respawn_time)
			var start : Vector2 = opp + dir * out_spin
			var end : Vector2 = start + dir * vfx_length
			play_state.draw_line(start, end, Color.GREEN)
		else:
			var vfx_length : float = 6
			play_state.draw_line(opp + dir * vfx_length, opp - dir * vfx_length, Color.GREEN)
