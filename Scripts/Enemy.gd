extends Control

class_name Enemy

enum EnemyState {MOVING, HUNTING, TRAPPED, RESPAWNING}

var difficulty_tier : int = 0
var speed_mod : float = 1.0
var play_state : PlayState = null
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var current_enemy_state : EnemyState
var max_respawn_time : float = 2
var respawn_remaining : float
var max_stun_time : float = 3
var stun_remaining : float

func set_mirror_pos(_remaining_fraction : float) -> void:
	assert(false, "Must be implemented in child class")

func set_pending_mirror_coordinates() -> void:
	assert(false, "Must be implemented in child class")
	
func render(_offset : Vector2) -> void:
	assert(false, "Must be implemented in child class")

func move_enemy(_delta : float) -> void:
	assert(false, "Must be implemented in child class")

func get_death_spot() -> Vector2i:
	assert(false, "Must be implemented in child class")
	return Vector2i.MAX

func get_distance_from_point_squared(_pos : Vector2i) -> float:
	assert(false, "Must be implemented in child class")
	return 500 * 500 + 500 * 500;

func get_tutorial_location() -> Vector2i:
	assert(false, "Must be implemented in child class")
	return Vector2i(250, 250)

func chose_spawn_spot() -> void:
	assert(false, "Must be implemented in child class")

func chose_new_goal() -> void:
	assert(false, "Must be implemented in child class")

func change_state(new_state : EnemyState) -> void:
	if new_state == EnemyState.RESPAWNING:
		current_enemy_state = new_state
		respawn_remaining = max_respawn_time * 10.0 / (10.0 + difficulty_tier)
		chose_spawn_spot()
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
	
func is_alive() -> bool:
	return current_enemy_state == EnemyState.MOVING || current_enemy_state == EnemyState.HUNTING

func init(ps : PlayState, tier : int) -> void:
	play_state = ps
	difficulty_tier = tier
	speed_mod = (10.0 + difficulty_tier) / 10.0
	change_state(EnemyState.RESPAWNING)
	chose_new_goal()

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
