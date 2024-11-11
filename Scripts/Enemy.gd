extends Control

class_name Enemy

var play_state : PlayState = null
var goal_pos : Vector2i
var move_work : Vector2
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var speed : float = 25

func init(ps : PlayState) -> void:
	play_state = ps
	goal_pos = ps.get_spawn_spot()

func chose_new_goal() -> void:
	goal_pos = play_state.get_spawn_spot()

func on_in_claimed_area() -> Vector2i:
	return play_state.get_spawn_spot()

func get_new_pos(delta: float) -> Vector2i:
	var move : Vector2i = play_state.enemy_pos
	var dir : Vector2 = (goal_pos - play_state.enemy_pos) as Vector2
	move_work += dir.normalized() * delta * speed
	if move_work.x >= 1:
		move.x += 1
		move_work.x -= 1.0
	elif move_work.x <= -1:
		move.x -= 1
		move_work.x += 1.0
	if move_work.y >= 1:
		move.y += 1
		move_work.y -= 1.0
	elif move_work.y <= -1:
		move.y -= 1
		move_work.y += 1.0
		
	if move == goal_pos:
		chose_new_goal()
	
	return move

func _process(_delta: float) -> void:
	pass
