extends StateMachineState

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5

var outer_lines : Array = []
var play_field : Control = null
var player_pos : Vector2i

func init_state(state_machine: StateMachine) -> void:
	active_process_mode = self.process_mode
	our_state_machine = state_machine
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()

var player_movement : Vector2 = Vector2.ZERO
func add_player_direction(dx : float, dy : float) -> void:
	dx = dx * 50.0
	dy = dy * 50.0
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

func move_if_possible(x : int, y : int) -> void:
	for line in outer_lines:
		if on_line(x, y, line[0], line[1]):
			player_pos = Vector2(x, y)
			return

func _process(delta: float) -> void:
	queue_redraw()
	rotate_player += 5.0 * delta
	#print("mouse = %s" % [get_local_mouse_position()])
	if Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S):
		add_player_direction(0, delta)
	elif Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W):
		add_player_direction(0, -delta)
	elif Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D):
		add_player_direction(delta, 0)
	elif Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A):
		add_player_direction(-delta, 0)

var rotate_player : float = 0
func _draw() -> void:
	if play_field == null:
		return

	var offset : Vector2 = play_field.global_position - self.global_position
	for line : Array in outer_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.WHITE)
	
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
		
func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_menu_pressed() -> void:
	leave_state("Menu")
