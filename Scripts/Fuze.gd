extends Control

class_name Fuze

var difficulty_tier : float = 0
var pos_on_field : Vector2i
var play_state : PlayState = null
var rotate : float = 0
var max_respawn_time : float = 2
var respawn_remaining : float
var current_state : FuzeState
var move_buffer : float = 0
var speed : float = 100
var speed_mod : float = 1

enum FuzeState {MOVING, RESPAWNING}

func init(ps : PlayState, tier : int) -> void:
	play_state = ps
	difficulty_tier = tier
	speed_mod = (10.0 + tier) / 10.0
	change_state(FuzeState.RESPAWNING)

func change_state(new_state : FuzeState) -> void:
	if new_state == FuzeState.RESPAWNING:
		current_state = FuzeState.RESPAWNING
		move_buffer = 0
		pos_on_field = play_state.point_opposite_player()
		respawn_remaining = max_respawn_time * 5.0 / (5.0 + difficulty_tier)
	else:
		current_state = FuzeState.MOVING

func move_fuze(delta : float) -> void:
	rotate += (delta * 1.5)
	if current_state == FuzeState.RESPAWNING:
		respawn_remaining -= delta
		if respawn_remaining < 0:
			change_state(FuzeState.MOVING)
		return
	
	move_buffer += delta * speed * speed_mod
	while move_buffer > 1:
		move_buffer -= 1
		
		var old_pos : Vector2i = pos_on_field
		pos_on_field = get_new_pos()
		if current_state == FuzeState.RESPAWNING:
			play_state.play_fuze_respawn()
			return

		if (old_pos - pos_on_field).length() > 2:
			print("Fuze teleported")
		
		if pos_on_field == play_state.player_pos:
			play_state.on_player_death()

func advance_along(start : Vector2i, end : Vector2i, pos : Vector2i) -> Vector2i:
	var dir : Vector2i = Enemy.get_v2i_direction(end - start)
	return pos + dir

func get_new_pos() -> Vector2i:
	for i in range(0, play_state.outer_lines.size()):
		var line = play_state.outer_lines[i]
		if play_state.on_line(pos_on_field.x, pos_on_field.y, line[0], line[1]):
			if pos_on_field == line[1]:
				var n : int = (i + 1) % play_state.outer_lines.size()
				var start : Vector2i = play_state.outer_lines[n][0]
				var end : Vector2i = play_state.outer_lines[n][1]
				return advance_along(start, end, pos_on_field)
			else:
				var start : Vector2i = play_state.outer_lines[i][0]
				var end : Vector2i = play_state.outer_lines[i][1]
				return advance_along(start, end, pos_on_field)

	# The outer_line has been moved out from under us, teleport to opposite of player
	change_state(FuzeState.RESPAWNING)
	play_state.play_fuze_respawn()
	return pos_on_field

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
