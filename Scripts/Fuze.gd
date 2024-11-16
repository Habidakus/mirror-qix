extends Control

class_name Fuze

var play_state : PlayState = null
var difficulty_tier : float = 0
var rotate : float = 0
var max_respawn_time : float = 2
var speed : float = 100
var speed_mod : float = 1

enum FuzeState {MOVING, RESPAWNING}

func set_pending_mirror_coordinates() -> void:
	assert(false, "needs to be implemented in child class")
func set_mirror_pos(_remaining_fraction : float) -> void:
	assert(false, "needs to be implemented in child class")
func init_all_agents() -> void:
	assert(false, "needs to be implemented in child class")
func move_all_agents(_delta : float) -> void:
	assert(false, "needs to be implemented in child class")
func is_this_location_death(_x : int, _y : int) -> bool:
	assert(false, "needs to be implemented in child class")
	return true
func render(_offset : Vector2) -> void:
	assert(false, "needs to be implemented in child class")
	
func init(ps : PlayState, tier : int) -> void:
	play_state = ps
	difficulty_tier = tier
	speed_mod = (10.0 + tier) / 10.0
	init_all_agents()

func move_fuze(delta : float) -> void:
	rotate += (delta * 1.5)
	move_all_agents(delta)

func advance_along(start : Vector2i, end : Vector2i, pos : Vector2i, adv : int) -> Vector2i:
	var dir : Vector2i = Enemy.get_v2i_direction(end - start)
	return pos + adv * dir

func get_new_pos(field_pos : Vector2i, dir : int) -> Vector2i:
	for i in range(0, play_state.outer_lines.size()):
		var line = play_state.outer_lines[i]
		if play_state.on_line(field_pos.x, field_pos.y, line[0], line[1]):
			if dir > 0 && field_pos == line[1]:
				var n : int = (i + 1) % play_state.outer_lines.size()
				var start : Vector2i = play_state.outer_lines[n][0]
				var end : Vector2i = play_state.outer_lines[n][1]
				return advance_along(start, end, field_pos, dir)
			elif dir < 0 && field_pos == line[0]:
				var n : int = (i + play_state.outer_lines.size() - 1) % play_state.outer_lines.size()
				var start : Vector2i = play_state.outer_lines[n][0]
				var end : Vector2i = play_state.outer_lines[n][1]
				return advance_along(start, end, field_pos, dir)
			else:
				var start : Vector2i = play_state.outer_lines[i][0]
				var end : Vector2i = play_state.outer_lines[i][1]
				return advance_along(start, end, field_pos, dir)

	return Vector2i.MAX
