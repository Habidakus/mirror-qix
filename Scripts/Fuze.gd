extends Control

class_name Fuze

var pos_on_field : Vector2i
var play_state : PlayState = null
var rotate : float = 0

func _process(delta : float) -> void:
	rotate += delta

func init(ps : PlayState) -> void:
	play_state = ps
	pos_on_field = play_state.point_opposite_player()

func move_fuze(delta : float) -> void:
	var old_pos : Vector2i = pos_on_field
	pos_on_field = get_new_pos(delta)
	if (old_pos - pos_on_field).length() > 2:
		print("Fuze teleported")
	
	if pos_on_field == play_state.player_pos:
		play_state.on_player_death()

func advance_along(start : Vector2i, end : Vector2i, pos : Vector2i) -> Vector2i:
	var dir : Vector2i = Enemy.get_v2i_direction(end - start)
	return pos + dir

func get_new_pos(_delta : float) -> Vector2i:
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
	# TODO: Implement respawn
	return play_state.point_opposite_player()

func render(offset : Vector2) -> void:
	var opp : Vector2 = offset + (pos_on_field as Vector2)
	var rp : int = round(rotate) as int
	var vfx_length : int = 4
	if rp % 2 == 0:
		play_state.draw_line(opp - Vector2(vfx_length, 0), opp + Vector2(vfx_length, 0), Color.GREEN)
		play_state.draw_line(opp - Vector2(0, vfx_length), opp + Vector2(0, vfx_length), Color.GREEN)
	elif rp % 2 == 1:
		play_state.draw_line(opp - Vector2(vfx_length, vfx_length), opp + Vector2(vfx_length, vfx_length), Color.GREEN)
		play_state.draw_line(opp - Vector2(-vfx_length, vfx_length), opp + Vector2(-vfx_length, vfx_length), Color.GREEN)
	
