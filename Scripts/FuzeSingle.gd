extends Fuze

class_name FuzeSingle

var pos_on_field : Vector2i
var mirror_start_pos : Vector2i
var mirror_end_pos : Vector2i
var respawn_remaining : float
var current_state : FuzeState
var move_buffer : float = 0

func set_pending_mirror_coordinates() -> void:
	mirror_start_pos = pos_on_field
	mirror_end_pos = play_state.mirror_v2i(pos_on_field)

func set_mirror_pos(remaining_fraction : float) -> void:
	pos_on_field = Enemy.lerp_v2i(mirror_end_pos, mirror_start_pos, remaining_fraction)

func init_all_agents() -> void:
	change_state(FuzeState.RESPAWNING)

func change_state(new_state : FuzeState) -> void:
	if new_state == FuzeState.RESPAWNING:
		current_state = FuzeState.RESPAWNING
		move_buffer = 0
		pos_on_field = play_state.point_opposite_player()
		respawn_remaining = max_respawn_time * 5.0 / (5.0 + difficulty_tier)
	else:
		current_state = FuzeState.MOVING

func move_all_agents(delta : float) -> void:
	if current_state == FuzeState.RESPAWNING:
		respawn_remaining -= delta
		if respawn_remaining < 0:
			change_state(FuzeState.MOVING)
		return
	
	move_buffer += delta * speed * speed_mod
	while move_buffer >= 1:
		move_buffer -= 1
		
		var old_pos : Vector2i = pos_on_field
		pos_on_field = get_new_pos(pos_on_field, 1)
		if pos_on_field == Vector2i.MAX:
			# The outer_line has been moved out from under us, teleport to opposite of player
			change_state(FuzeState.RESPAWNING)
			play_state.play_fuze_respawn()
			return
		
		if current_state == FuzeState.RESPAWNING:
			play_state.play_fuze_respawn()
			return

		if (old_pos - pos_on_field).length() > 2:
			print("Fuze teleported")
		
		if pos_on_field == play_state.player_pos:
			play_state.on_player_death()

func is_this_location_death(x : int, y : int) -> bool:
	return x == pos_on_field.x && y == pos_on_field.y

func render(offset : Vector2) -> void:
	var opp : Vector2 = offset + (pos_on_field as Vector2)
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
