extends StateMachineState

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5
@export var player_speed : float = 200

var outer_lines : Array = []
var inner_lines : Array = []
var score : int = 0
var play_field : Control = null
var player_pos : Vector2i
var player_on_outer_lines : bool = true

func init_state(state_machine: StateMachine) -> void:
	active_process_mode = self.process_mode
	our_state_machine = state_machine
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()

var player_movement : Vector2 = Vector2.ZERO
func add_player_direction(dx : float, dy : float) -> void:
	dx = dx * player_speed
	dy = dy * player_speed
	if player_movement == Vector2.ZERO:
		player_movement = Vector2(dx, dy)
		print("Starting movement")
		return
	var m : Vector2 = player_movement * Vector2(dx, dy)
	if m == Vector2.ZERO:
		player_movement = Vector2(dx, dy)
		print("Movement changed axis")
		return
	if m.x < 0 || m.y < 0:
		player_movement = Vector2(dx, dy)
		print("Movement changed direction")
		return
	
	player_movement += Vector2(dx, dy)
	if player_movement.x >= 1:
		move_if_possible(player_pos.x + 1, player_pos.y)
		player_movement.x -= 1
	elif player_movement.y >= 1:
		move_if_possible(player_pos.x, player_pos.y + 1)
		player_movement.y -= 1
	elif player_movement.x <= -1:
		move_if_possible(player_pos.x - 1, player_pos.y)
		player_movement.x += 1
	elif player_movement.y <= -1:
		move_if_possible(player_pos.x, player_pos.y - 1)
		player_movement.y += 1

func on_line(x : int, y : int, start : Vector2i, end : Vector2i) -> bool:
	if start.x == end.x and start.x == x:
		if start.y == y || end.y == y:
			return true;
		var m : float = (start.y - y) * (end.y - y)
		return m < 0
	if start.y == end.y and start.y == y:
		if start.x == x || end.x == x:
			return true;
		var m : float = (start.x - x) * (end.x - x)
		return m < 0
	#assert(false, "Odd line %s to %s" % [start, end])
	return false

func is_on_outer_line(x : int, y : int) -> bool:
	for line in outer_lines:
		if on_line(x, y, line[0], line[1]):
			return true
	return false

func is_on_inner_line(x : int, y : int) -> bool:
	for line in inner_lines:
		if on_line(x, y, line[0], line[1]):
			return true
	return false

func is_direction_on_outer_line(x : int, y : int) -> bool:
	return is_on_outer_line(player_pos.x + x, player_pos.y + y)

func does_extend_line(x : int, y: int, start : Vector2i, end : Vector2i) -> bool:
	if start.x == end.x && start.x == x:
		var dy : int = y - end.y
		if abs(dy) != 1:
			return false
		# ensure we're still going the same direction
		return ((end.y - start.y) * dy) > 0
	if start.y == end.y && start.y == y:
		var dx : int = x - end.x
		if abs(dx) != 1:
			return false
		# ensure we're still going the same direction
		return ((end.x - start.x) * dx) > 0
	return false

func measure_area(lines : Array) -> int:
	# I believe this calucates the area of our polyomino
	var x : int = 0
	var y : int = 0
	var area : int = 0
	for line : Array in lines:
		var start : Vector2i = line[0]
		var end : Vector2i = line[1]
		if end.x > start.x:
			var d : int = (end.x - start.x)
			x += d
			area += d * y
		elif end.x < start.x:
			var d : int = (start.x - end.x)
			x -= d
			area -= d * y
		elif end.y > start.y:
			var d : int = (end.x - start.x)
			y += d
		elif end.y < start.y:
			var d : int = (start.x - end.x)
			y -= d
		else:
			assert("what? line = %s to %s" % [start, end])
	if area < 0:
		return 0 - area
	else:
		return area

func complete_loop(x : int, y : int) -> void:
	if does_extend_line(x, y, inner_lines.back()[0], inner_lines.back()[1]):
		inner_lines.back()[1] = Vector2i(x, y)
	else:
		inner_lines.append([player_pos, Vector2i(x, y)])
	player_pos = Vector2i(x, y)
	var two_loops : Array = create_both_loops()
	var loop_1_area : int = measure_area(two_loops[0])
	var loop_2_area : int = measure_area(two_loops[1])
	if loop_1_area < loop_2_area:
		score += loop_1_area
		outer_lines = two_loops[1]
	else:
		score += loop_2_area
		outer_lines = two_loops[0]

func move_if_possible(x : int, y : int) -> void:
	if player_on_outer_lines:
		if is_on_outer_line(x, y):
			player_pos = Vector2i(x, y)
		return
	# Process building new inner line
	if is_on_outer_line(x, y):
		# completed area
		complete_loop(x, y)
		return
	if is_on_inner_line(x, y):
		on_player_death()
		return
	if does_extend_line(x, y, inner_lines.back()[0], inner_lines.back()[1]):
		inner_lines.back()[1] = Vector2i(x, y)
		player_pos = Vector2i(x, y)
		return
	inner_lines.append([player_pos, Vector2i(x, y)])
	player_pos = Vector2i(x, y)

func _process(delta: float) -> void:
	queue_redraw()
	rotate_player += 5.0 * delta
	process_player_input(delta)

func process_player_input(delta : float) -> void:
	if player_on_outer_lines == false:
		# player is burning new path
		process_inner_line_input(delta)
		return
	if process_outer_line_input(delta):
		return
	if Input.is_key_pressed(KEY_SPACE):
		process_inner_path_start()

func start_inner_path(x : int, y : int) -> void:
	assert(inner_lines.is_empty())
	var ix : int = player_pos.x + x
	var iy : int = player_pos.y + y
	if ix < 0 || iy < 0 || ix >= play_field.size.x || iy >= play_field.size.y:
		# Player trying to move outside of playing area
		return
	if self.is_on_outer_line(ix, iy):
		# player trying to jump off one line onto another? Shouldn't happen, but stop it
		print("Shouldn't happen?! Player starting innner line onto outer line")
		return
	player_on_outer_lines = false
	inner_lines.append([player_pos, Vector2i(ix, iy)])
	player_pos = Vector2i(ix, iy)

func process_inner_path_start() -> void:
	if (Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S)):
		start_inner_path(0, 1);
	elif (Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W)):
		start_inner_path(0, -1);
	elif (Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D)):
		start_inner_path(1, 0);
	elif (Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A)):
		start_inner_path(-1, 0);
	# else player is just holding down space but no direction - that's ok.

func process_inner_line_input(delta : float) -> void:
	if (Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S)): # && !is_direction_on_outer_line(0, 1):
		add_player_direction(0, delta)
	elif (Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W)): # && !is_direction_on_outer_line(0, -1):
		add_player_direction(0, -delta)
	elif (Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D)): # && !is_direction_on_outer_line(1, 0):
		add_player_direction(delta, 0)
	elif (Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A)): # && !is_direction_on_outer_line(-1, 0):
		add_player_direction(-delta, 0)
	
func process_outer_line_input(delta : float) -> bool:
	if (Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S)) && is_direction_on_outer_line(0, 1):
		add_player_direction(0, delta)
		return true
	elif (Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W)) && is_direction_on_outer_line(0, -1):
		add_player_direction(0, -delta)
		return true
	elif (Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D)) && is_direction_on_outer_line(1, 0):
		add_player_direction(delta, 0)
		return true
	elif (Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A)) && is_direction_on_outer_line(-1, 0):
		add_player_direction(-delta, 0)
		return true
	return false

var rotate_player : float = 0
func _draw() -> void:
	if play_field == null:
		return

	var offset : Vector2 = play_field.global_position - self.global_position
	for line : Array in outer_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.WHITE)
	for line : Array in inner_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.RED)
	
	var player_length : int = 4
	var rp : int = round(rotate_player) as int
	var p_loc : Vector2 = offset + (player_pos as Vector2)
	if rp % 2 == 0:
		self.draw_line(p_loc - Vector2(player_length, 0), p_loc + Vector2(player_length, 0), Color.BLUE)
		self.draw_line(p_loc - Vector2(0, player_length), p_loc + Vector2(0, player_length), Color.BLUE)
	elif rp % 2 == 1:
		self.draw_line(p_loc - Vector2(player_length, player_length), p_loc + Vector2(player_length, player_length), Color.BLUE)
		self.draw_line(p_loc - Vector2(-player_length, player_length), p_loc + Vector2(-player_length, player_length), Color.BLUE)

func add_line(start : Vector2i, end : Vector2i) -> void:
	outer_lines.append([start, end])

func init_game() -> void:
	play_field = find_child("PlayField") as Control
	outer_lines = []
	inner_lines = []
	score = 0
	player_on_outer_lines = true
	var pfs : Vector2i = Vector2i(int(play_field.size.x) - 1, int(play_field.size.y) - 1) 
	add_line(Vector2i(0,0), Vector2i(pfs.x, 0))
	add_line(Vector2i(pfs.x, 0), pfs)
	add_line(pfs, Vector2i(0, pfs.y))
	add_line(Vector2i(0, pfs.y), Vector2i(0,0))
	play_field.hide() # TODO: Move the drawing code to a script running on the play_field
	player_pos = Vector2(0, play_field.size.y / 2)

func enter_state() -> void:
	super.enter_state()
	if fade_in:
		self.modulate = Color(Color.WHITE, 0)
		var tween : Tween = get_tree().create_tween()
		var destination_color : Color = Color(Color.WHITE, 1)
		tween.tween_property(self, "modulate", destination_color, fade_time)
	call_deferred("init_game")

var leave_tween : Tween = null
func leave_state(next_state : String) -> void:
	if fade_out:
		if leave_tween != null && leave_tween.is_running():
			return
		leave_tween = get_tree().create_tween()
		self.modulate = Color(Color.WHITE, 1)
		var destination_color : Color = Color(Color.WHITE, 0)
		leave_tween.tween_property(self, "modulate", destination_color, fade_time)
		await leave_tween.finished
		our_state_machine.switch_state(next_state)
	else:
		our_state_machine.switch_state(next_state)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

func on_player_death() -> void:
	print("TODO: Implement better death handling")
	leave_state("Menu")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_menu_pressed() -> void:
	leave_state("Menu")
