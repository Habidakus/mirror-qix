extends Control

class_name Enemy

enum EnemyState {MOVING, HUNTING, TRAPPED, RESPAWNING}

var difficulty_tier : int = 0
var speed_mod : float = 1.0
var pos_on_field : Vector2i
var mirror_start_pos : Vector2i
var mirror_end_pos : Vector2i
var play_state : PlayState = null
var goal_pos : Vector2i
var move_work : Vector2
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var speed : float = 75
var current_enemy_state : EnemyState
var max_respawn_time : float = 2
var respawn_remaining : float
var max_stun_time : float = 3
var stun_remaining : float

func set_pending_mirror_coordinates() -> void:
	mirror_start_pos = pos_on_field
	mirror_end_pos = play_state.mirror_v2i(pos_on_field)
	move_work = Vector2(-move_work.x, move_work.y)

func set_mirror_pos(remaining_fraction : float) -> void:
	pos_on_field = Enemy.lerp_v2i(mirror_end_pos, mirror_start_pos, remaining_fraction)

func change_state(new_state : EnemyState) -> void:
	if new_state == EnemyState.RESPAWNING:
		current_enemy_state = new_state
		respawn_remaining = max_respawn_time * 10.0 / (10.0 + difficulty_tier)
		pos_on_field = get_spawn_spot()
		return
	if new_state == EnemyState.TRAPPED:
		current_enemy_state = new_state
		stun_remaining = max_stun_time * 10.0 / (10.0 + difficulty_tier)
		play_state.play_enemy_trapped()
		return
	if new_state == EnemyState.MOVING:
		assert(current_enemy_state != EnemyState.MOVING)
		current_enemy_state = new_state
		chose_new_goal()
		return
	if new_state == EnemyState.HUNTING:
		assert(current_enemy_state != EnemyState.HUNTING)
		current_enemy_state = new_state
		chose_new_goal()
		return
	assert(false)
	
func init(ps : PlayState, tier : int) -> void:
	play_state = ps
	difficulty_tier = tier
	speed_mod = (10.0 + difficulty_tier) / 10.0
	change_state(EnemyState.RESPAWNING)
	chose_new_goal()
	#print("Enemy speed = %s" % [speed * speed_mod])

func _process(delta: float) -> void:
	if current_enemy_state == EnemyState.RESPAWNING:
		respawn_remaining -= delta
		if respawn_remaining <= 0:
			if play_state.is_in_claimed_area(pos_on_field.x, pos_on_field.y):
				change_state(EnemyState.TRAPPED)
			else: 
				change_state(EnemyState.MOVING)
			return
	if current_enemy_state == EnemyState.TRAPPED:
		stun_remaining -= delta
		if stun_remaining <= 0:
			change_state(EnemyState.RESPAWNING)
			play_state.play_enemy_respawn()
			return

func chose_new_goal_and_state() -> void:
	if current_enemy_state == EnemyState.MOVING:
		if play_state.player_on_outer_lines == false:
			change_state(EnemyState.HUNTING)
			return
	elif current_enemy_state == EnemyState.HUNTING:
		if play_state.player_on_outer_lines:
			change_state(EnemyState.MOVING)
			return
	chose_new_goal()

func chose_new_goal() -> void:
	move_work = Vector2.ZERO
	goal_pos = get_goal_spot()

func advance_movement_cursor(delta : float) -> void:
	var dir : Vector2 = (goal_pos - pos_on_field) as Vector2
	move_work += dir.normalized() * delta * speed * speed_mod

func get_new_pos_delta() -> Vector2i:
	if abs(move_work.x) > abs(move_work.y):
		if move_work.x >= 1:
			move_work.x -= 1.0
			return Vector2i(1, 0)
		elif move_work.x <= -1:
			move_work.x += 1.0
			return Vector2i(-1, 0)
	else:
		if move_work.y >= 1:
			move_work.y -= 1.0
			return Vector2i(0, 1)
		elif move_work.y <= -1:
			move_work.y += 1.0
			return Vector2i(0, -1)
	return Vector2i.ZERO

func render(offset : Vector2) -> void:
	var loc : Vector2 = offset + (pos_on_field as Vector2)
	var radius : float = 3
	if current_enemy_state == EnemyState.TRAPPED:
		var trapped_phase : int = int(10.0 * stun_remaining / max_stun_time) % 2
		var trapped_radius : float = radius * (0.5 + float(trapped_phase) * 1.5)
		play_state.draw_circle(loc, trapped_radius, Color.BLACK)
	elif current_enemy_state == EnemyState.MOVING:
		play_state.draw_circle(loc, radius, Color.DARK_VIOLET)
	elif current_enemy_state == EnemyState.HUNTING:
		play_state.draw_circle(loc, radius, Color.VIOLET)
	else:
		var fraction_dead : float = respawn_remaining / max_respawn_time
		var dead_radius : float = (fraction_dead * 10 * radius) + radius
		var alpha : float = 1.0 - fraction_dead
		var color : Color = Color(Color.DARK_VIOLET, alpha)
		play_state.draw_circle(loc, dead_radius, color)

func move_enemy(delta : float) -> void:
	if current_enemy_state == EnemyState.TRAPPED || current_enemy_state == EnemyState.RESPAWNING:
		return
	
	advance_movement_cursor(delta)
	while true:
		var movement_delta : Vector2i = get_new_pos_delta()
		if movement_delta == Vector2i.ZERO:
			return
		
		var old_pos : Vector2i = pos_on_field
		var was_on_outer_line : bool = play_state.is_on_outer_line(pos_on_field.x, pos_on_field.y)
		var next_pos = pos_on_field + movement_delta
		var will_be_on_outer_line : bool = play_state.is_on_outer_line(next_pos.x, next_pos.y)
		var will_be_in_claimed_area : bool = play_state.is_in_claimed_area(next_pos.x, next_pos.y)
		if was_on_outer_line && (will_be_on_outer_line || will_be_in_claimed_area):
			chose_new_goal_and_state()
			return

		pos_on_field = next_pos

		if play_state.is_on_inner_line(pos_on_field.x, pos_on_field.y):
			play_state.on_player_death()
			return
	
		if pos_on_field == goal_pos:
			chose_new_goal_and_state()
			return

		if will_be_on_outer_line: # && old_pos != pos_on_field:
			move_work = Vector2.ZERO
			chose_new_goal_and_state()
			print("Enemy from %s to %s bounced off outer line - new goal: %s" % [old_pos, pos_on_field, goal_pos])
			return

		if will_be_in_claimed_area:
			#print("Enemy from %s to %s on claimed spot" % [old_pos, pos_on_field])
			#if !on_outer_line:
			change_state(EnemyState.TRAPPED)
			return

static func lerp_v2i(start : Vector2i, end : Vector2i, frac : float) -> Vector2i:
	var x : int = lerp(start.x, end.x, frac)
	var y : int = lerp(start.y, end.y, frac)
	return Vector2i(x, y)

static func get_v2i_direction_from_float(x : float, y : float) -> Vector2i:
	if x == 0 && y == 0:
		return Vector2i.ZERO
	if abs(x) > abs(y):
		if x > 0:
			return Vector2i(1, 0)
		else:
			return Vector2i(-1, 0)
	else:
		if y > 0:
			return Vector2i(0, 1)
		else:
			return Vector2i(0, -1)
			
static func get_v2i_direction(v : Vector2i) -> Vector2i:
	if v == Vector2i.ZERO:
		return Vector2i.ZERO
	if abs(v.x) == abs(v.y):
		return v / abs(v.x)
	if abs(v.x) > abs(v.y):
		if v.x > 0:
			return Vector2i(1, 0)
		else:
			return Vector2i(-1, 0)
	else:
		if v.y > 0:
			return Vector2i(0, 1)
		else:
			return Vector2i(0, -1)

func get_spawn_spot() -> Vector2i:
	var best_spot : Vector2i
	var best_dist : int = 0
	var potential_spots : int = 0
	while potential_spots < 10:
		var x : int = rng.randi_range(0, int(play_state.play_field.size.x) - 1)
		var y : int = rng.randi_range(0, int(play_state.play_field.size.y) - 1)
		if !play_state.is_in_claimed_area(x, y):
			potential_spots += 1
			var dist_squared = (Vector2i(x,y) - play_state.player_pos).length_squared()
			if best_spot == null || dist_squared > best_dist:
				best_spot = Vector2i(x, y)
				best_dist = dist_squared
	return best_spot

func get_goal_spot() -> Vector2i:
	var best_spot : Vector2i
	var best_dist : int = 0
	var potential_spots : int = 0
	var currently_in_claimed_area : bool = play_state.is_in_claimed_area(pos_on_field.x, pos_on_field.y)
	while potential_spots < 10:
		var x : int = rng.randi_range(0, int(play_state.play_field.size.x) - 1)
		var y : int = rng.randi_range(0, int(play_state.play_field.size.y) - 1)
		if play_state.is_in_claimed_area(x, y) || play_state.is_on_outer_line(x, y):
			continue
		var dir : Vector2i = get_v2i_direction(Vector2i(x,y) - pos_on_field)
		var nx : int = pos_on_field.x + dir.x
		var ny : int = pos_on_field.y + dir.y
		if !currently_in_claimed_area:
			if play_state.is_in_claimed_area(nx, ny) || play_state.is_on_outer_line(nx, ny):
				continue
		potential_spots += 1
		if current_enemy_state == EnemyState.HUNTING:
			var dist_squared = (Vector2i(x,y) - play_state.player_pos).length_squared()
			if best_spot == null || best_dist == 0 || dist_squared < best_dist:
				best_spot = Vector2i(x, y)
				best_dist = dist_squared
		else:
			var dist_squared = (Vector2i(x,y) - pos_on_field).length_squared()
			if best_spot == null || best_dist == 0 || dist_squared < best_dist:
				best_spot = Vector2i(x, y)
				best_dist = dist_squared
	return best_spot
