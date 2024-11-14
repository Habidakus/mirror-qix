extends StateMachineState

class_name PlayState

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5
@export var player_speed_inner : float = 100
@export var player_speed_outer : float = 150

enum PlayerState { UNINITIALIZED, PLAYING, DEAD, WON_PAUSE }
var player_state : PlayerState = PlayerState.UNINITIALIZED

var assert_color : bool = false

var enemy : Enemy = null
var fuze : Fuze = null
var outer_lines : Array = []
var inner_lines : Array = []
var completed_rects : Array = []
#var score : int = 0
var area_covered : int = 0
var area_needed : int = 0
var fraction_of_field_needed : float = 0.75
var percent_covered : float = 0
var percent_needed_to_win : float = 0
var player_travel_speaker : AudioStreamPlayer = null
var player_event_speaker : AudioStreamPlayer = null
var enemy_speaker : AudioStreamPlayer = null
var fuze_speaker : AudioStreamPlayer = null
var player_moving_pitch_scale : float = 2
var player_stopped_pitch_scale : float = 1
var play_field : Control = null
var score_label : Label = null
var tab_container : TabContainer = null
var tab_child_controls : Control = null
var tab_child_play : Control = null
var tab_child_config : Control = null
var tab_child_unlock : Control = null
var progress_bar : ProgressBar = null
var player_pos : Vector2i
var player_on_outer_lines : bool = true
var game_state_label : Label = null
var restart_label : Label = null
var difficulty_tier : int = 0
var score_multiplier : float = 1.0
var up_button : Button = null
var down_button : Button = null
var right_button : Button = null
var left_button : Button = null
var draw_button : Button = null
var score_value_label : Label = null
var unlocks_available_label : Label = null
var build_line_config_section : Control = null
var build_protection_option_button : OptionButton = null
var build_path_backup_button : Button = null
var build_path_crossing_button : Button = null
var build_speed_slow_button : Button = null
var build_speed_very_slow_button : Button = null
var build_speed_fast_button : Button = null
var build_speed_very_fast_button : Button = null
var area_covered_config_section : Control = null
var coverage_option_button : OptionButton = null
var cover_eighty_percent_button : Button = null
var cover_eightyfive_percent_button : Button = null
var cover_ninety_percent_button : Button = null

var audio_stream_fuze_resurrection : AudioStream = preload("res://Sound/spawn_02.wav")
var audio_stream_enemy_resurrection : AudioStream = preload("res://Sound/spawn_01.wav")
var audio_stream_enemy_trapped : AudioStream = preload("res://Sound/powerup_03.wav")
var audio_stream_player_death : AudioStream = preload("res://Sound/death_01.wav")
var audio_stream_player_victory : AudioStream = preload("res://Sound/powerup_02.wav")
var audio_stream_player_area_capture : AudioStream = preload("res://Sound/hit_01.wav")

var unlocks_available : int = 0
var points_until_next_unlock_credit : float = 1000
var increase_in_unlock_cost_per_unlock : float = 2.0
# TODO: Organize these into sets of resources
enum InnerLoopProtection { NONE, FULL, BACKUP }
var perk_inner_loop_protection : InnerLoopProtection = InnerLoopProtection.FULL
var perk_unlock_allow_backtracking_inner_loop : bool = false
var perk_multiple_stop_backtracking_inner_loop : float = 1.15
var perk_unlock_allow_crossing_inner_loop : bool = false
var perk_multiple_no_inner_loop_protection : float = 1.25
var perk_unlock_eighty_percent_coverage : bool = false
var perk_multiple_eighty_percent_coverage : float = 1.5
var perk_unlock_eightyfive_percent_coverage : bool = false
var perk_multiple_eightyfive_percent_coverage : float = 2
var perk_unlock_ninety_percent_coverage : bool = false
var perk_multiple_ninety_percent_coverage : float = 2.75

func are_any_unlocks_available() -> bool:
	if unlocks_available == 0:
		return false
	if !perk_unlock_allow_backtracking_inner_loop:
		return true
	if !perk_unlock_allow_crossing_inner_loop:
		return true
	if !perk_unlock_eighty_percent_coverage || !perk_unlock_eightyfive_percent_coverage || !perk_unlock_ninety_percent_coverage:
		return true
	return false

func are_any_configs_unlocked() -> bool:
	if perk_unlock_allow_backtracking_inner_loop:
		return true
	if perk_unlock_allow_crossing_inner_loop:
		return true
	if perk_unlock_eighty_percent_coverage || perk_unlock_eightyfive_percent_coverage || perk_unlock_ninety_percent_coverage:
		return true
	return false
	
func setup_config_tab() -> void:
	
	if are_any_configs_unlocked():
		show_tab(tab_child_config)
	else:
		hide_tab(tab_child_config)
		return
	
	if perk_unlock_allow_backtracking_inner_loop || perk_unlock_allow_crossing_inner_loop:
		build_line_config_section.show()
		build_protection_option_button.clear()
		build_protection_option_button.add_item("Full protections vs crossing build line", InnerLoopProtection.FULL)
		if perk_inner_loop_protection == InnerLoopProtection.FULL:
			build_protection_option_button.selected = build_protection_option_button.get_item_index(InnerLoopProtection.FULL)
		if perk_unlock_allow_backtracking_inner_loop:
			build_protection_option_button.add_item("Protection only against backing up", InnerLoopProtection.BACKUP)
			if perk_inner_loop_protection == InnerLoopProtection.BACKUP:
				build_protection_option_button.selected = build_protection_option_button.get_item_index(InnerLoopProtection.BACKUP)
		if perk_unlock_allow_crossing_inner_loop:
			build_protection_option_button.add_item("No protection against crossing build line", InnerLoopProtection.NONE)
			if perk_inner_loop_protection == InnerLoopProtection.NONE:
				build_protection_option_button.selected = build_protection_option_button.get_item_index(InnerLoopProtection.NONE)
	else:
		build_line_config_section.hide()
	var space_bar_config_section : Control = tab_child_config.find_child("SpaceBarConfig")
	space_bar_config_section.hide()
	var tab_config_section : Control = tab_child_config.find_child("TabConfig")
	tab_config_section.hide()
	
	if perk_unlock_eighty_percent_coverage:
		area_covered_config_section.show()
		coverage_option_button.clear()
		coverage_option_button.add_item("75%", 75)
		coverage_option_button.add_item("80%% (score x%.2f)" % perk_multiple_eighty_percent_coverage, 80)
		if perk_unlock_eightyfive_percent_coverage:
			coverage_option_button.add_item("85%% (score x%.2f)" % perk_multiple_eightyfive_percent_coverage, 85)
		if perk_unlock_ninety_percent_coverage:
			coverage_option_button.add_item("90%% (score x%.2f)" % perk_multiple_ninety_percent_coverage, 90)
		if fraction_of_field_needed >= 0.9:
			coverage_option_button.selected = coverage_option_button.get_item_index(90)
		elif fraction_of_field_needed >= 0.85:
			coverage_option_button.selected = coverage_option_button.get_item_index(85)
		elif fraction_of_field_needed >= 0.8:
			coverage_option_button.selected = coverage_option_button.get_item_index(80)
		else:
			coverage_option_button.selected = coverage_option_button.get_item_index(75)
	else:
		area_covered_config_section.hide()
		
func setup_unlock_tab() -> void:
	var picking_disabled : bool = false
	if are_any_unlocks_available():
		show_tab(tab_child_unlock)
	else:
		if is_tab_currently_selected(tab_child_unlock):
			picking_disabled = true
		else:
			hide_tab(tab_child_unlock)
			return

	unlocks_available_label.text = str(unlocks_available)
	# Build Crossing Protection
	if perk_unlock_allow_backtracking_inner_loop:
		build_path_backup_button.button_pressed = true
		build_path_backup_button.disabled = true
	else:
		build_path_backup_button.button_pressed = false
		build_path_backup_button.disabled = picking_disabled
	if perk_unlock_allow_crossing_inner_loop:
		build_path_crossing_button.button_pressed = true
		build_path_crossing_button.disabled = true
	else:
		build_path_crossing_button.button_pressed = false
		build_path_crossing_button.disabled = picking_disabled
		
	# Build speed unlocks
	build_speed_slow_button.button_pressed = false
	build_speed_slow_button.disabled = true
	build_speed_very_slow_button.button_pressed = false
	build_speed_very_slow_button.disabled = true
	build_speed_fast_button.button_pressed = false
	build_speed_fast_button.disabled = true
	build_speed_very_fast_button.button_pressed = false
	build_speed_very_fast_button.disabled = true
	
	# coverage
	if !perk_unlock_eighty_percent_coverage:
		cover_eighty_percent_button.button_pressed = false
		cover_eighty_percent_button.disabled = picking_disabled
		cover_eightyfive_percent_button.hide()
		cover_ninety_percent_button.hide()
	elif !perk_unlock_eightyfive_percent_coverage:
		cover_eighty_percent_button.button_pressed = true
		cover_eighty_percent_button.disabled = true
		cover_eightyfive_percent_button.show()
		cover_eightyfive_percent_button.button_pressed = false
		cover_eightyfive_percent_button.disabled = picking_disabled
	elif !perk_unlock_ninety_percent_coverage:
		cover_eighty_percent_button.button_pressed = true
		cover_eighty_percent_button.disabled = true
		cover_eightyfive_percent_button.button_pressed = true
		cover_eightyfive_percent_button.disabled = true
		cover_ninety_percent_button.show()
		cover_ninety_percent_button.button_pressed = false
		cover_ninety_percent_button.disabled = picking_disabled
	else:
		cover_eighty_percent_button.button_pressed = true
		cover_eighty_percent_button.disabled = true
		cover_eightyfive_percent_button.button_pressed = true
		cover_eightyfive_percent_button.disabled = true
		cover_ninety_percent_button.button_pressed = true
		cover_ninety_percent_button.disabled = true

func on_build_protection_option_button(index : int) -> void:
	perk_inner_loop_protection = build_protection_option_button.get_item_id(index) as InnerLoopProtection

func on_coverage_option_button(index : int) -> void:
	fraction_of_field_needed = (coverage_option_button.get_item_id(index) as float) / 100.0

func on_build_path_backup_button() -> void:
	if perk_unlock_allow_backtracking_inner_loop == false:
		perk_unlock_allow_backtracking_inner_loop = true
		unlocks_available -= 1
		setup_config_tab()
		setup_unlock_tab()

func on_build_path_crossing_button() -> void:
	if perk_unlock_allow_crossing_inner_loop == false:
		perk_unlock_allow_crossing_inner_loop = true
		unlocks_available -= 1
		setup_config_tab()
		setup_unlock_tab()

func on_cover_eighty_percent_button() -> void:
	if perk_unlock_eighty_percent_coverage == false:
		perk_unlock_eighty_percent_coverage = true
		unlocks_available -= 1
		setup_config_tab()
		setup_unlock_tab()

func on_cover_eightyfive_percent_button() -> void:
	if perk_unlock_eightyfive_percent_coverage == false:
		perk_unlock_eightyfive_percent_coverage = true
		unlocks_available -= 1
		setup_config_tab()
		setup_unlock_tab()

func on_cover_ninety_percent_button() -> void:
	if perk_unlock_ninety_percent_coverage == false:
		perk_unlock_ninety_percent_coverage = true
		unlocks_available -= 1
		setup_config_tab()
		setup_unlock_tab()

func on_build_slow_button() -> void:
	pass
func on_build_very_slow_button() -> void:
	pass
func on_build_fast_button() -> void:
	pass
func on_build_very_fast_button() -> void:
	pass

func init_state(state_machine: StateMachine) -> void:
	active_process_mode = self.process_mode
	our_state_machine = state_machine
	player_state = PlayerState.UNINITIALIZED
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()

var player_movement : Vector2 = Vector2.ZERO
var player_forbidden_movement : Vector2i = Vector2.ZERO
func add_player_direction(dx : float, dy : float) -> void:
	var tier_modifier : float = 10 / float(10 + difficulty_tier)
	if player_on_outer_lines:
		dx = dx * player_speed_outer * tier_modifier
		dy = dy * player_speed_outer * tier_modifier
	else:
		dx = dx * player_speed_inner * tier_modifier
		dy = dy * player_speed_inner * tier_modifier
	if player_movement == Vector2.ZERO:
		player_movement = Vector2(dx, dy)
		player_travel_speaker.set_pitch_scale(player_moving_pitch_scale)
		return
	var m : Vector2 = player_movement * Vector2(dx, dy)
	if m == Vector2.ZERO:
		# If m == 0,0 then we have switched our vector to perpendicular to what
		# it was, replace stored movement with new movement
		player_movement = Vector2(dx, dy)
		player_travel_speaker.set_pitch_scale(player_moving_pitch_scale)
		return
	var dxy_direction : Vector2i = Enemy.get_v2i_direction_from_float(dx, dy)
	if perk_inner_loop_protection != InnerLoopProtection.NONE && !player_on_outer_lines:
		if player_forbidden_movement != Vector2i.ZERO && dxy_direction == player_forbidden_movement:
			player_movement = Vector2.ZERO
			player_travel_speaker.set_pitch_scale(player_stopped_pitch_scale)
			return
	if m.x < 0 || m.y < 0:
		# if either m is negative, we've switched directions along an axis, so
		# replace stored movement with new movement
		player_movement = Vector2(dx, dy)
		player_travel_speaker.set_pitch_scale(player_moving_pitch_scale)
		return
	
	player_travel_speaker.set_pitch_scale(player_moving_pitch_scale)
	player_movement += Vector2(dx, dy)
	player_forbidden_movement = dxy_direction * -1

	var can_continue : bool = true
	while can_continue:
		if player_movement.x >= 1:
			can_continue = move_if_possible(player_pos.x + 1, player_pos.y)
			player_movement.x -= 1
		elif player_movement.y >= 1:
			can_continue = move_if_possible(player_pos.x, player_pos.y + 1)
			player_movement.y -= 1
		elif player_movement.x <= -1:
			can_continue = move_if_possible(player_pos.x - 1, player_pos.y)
			player_movement.x += 1
		elif player_movement.y <= -1:
			can_continue = move_if_possible(player_pos.x, player_pos.y - 1)
			player_movement.y += 1
		else:
			can_continue = false

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

func get_outer_line_element(pos : Vector2i) -> Array:
	for line in outer_lines:
		if on_line(pos.x, pos.y, line[0], line[1]):
			return line
	assert(false, "Asked for outer line containing %s, which no line does" % pos)
	return []

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
			#print("East line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		elif end.x < start.x:
			var d : int = (start.x - end.x)
			x -= d
			area -= d * y
			#print("West line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		elif end.y > start.y:
			var d : int = (end.y - start.y)
			y += d
			#print("South line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		elif end.y < start.y:
			var d : int = (start.y - end.y)
			y -= d
			#print("North line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		else:
			assert("what? line = %s to %s" % [start, end])
	if area < 0:
		area = 0 - area
	#print("Area = %s" % [area])
	return area

func hack_consolidate_neighbors(loop: Array) -> Array:
	var mark_for_remove : Array = []
	for i in range(0, loop.size()):
		var n : int = (i + 1) % loop.size()
		if are_path_elements_same_axis(loop[i], loop[n]):
			assert(loop[i][1] == loop[n][0])
			mark_for_remove.append(n)
	if mark_for_remove.is_empty():
		return loop
	var ret_val : Array = []
	for i in range(0, loop.size()):
		var n : int = (i + 1) % loop.size()
		var will_remove_next : bool = mark_for_remove.count(n) > 0
		var will_remove_current : bool = mark_for_remove.count(i) > 0
		assert(will_remove_next == false || will_remove_current == false, "We need to remove two in a row?!")
		if will_remove_next:
			ret_val.append([loop[i][0], loop[n][1]])
		elif !will_remove_current:
			ret_val.append(loop[i])
	return ret_val

func hack_reverse_loop(loop : Array) -> Array:
	var retVal : Array = []
	for i in range(0, loop.size()):
		var n : int = loop.size() - (i + 1)
		retVal.append([loop[n][1], loop[n][0]])
	return retVal

func create_both_loops() -> Array:
	var start_point : Vector2i = inner_lines.front()[0]
	var end_point : Vector2i = inner_lines.back()[1]
	var outer_start_index : int = -1
	var outer_end_index : int = -1
	for i in range(0, outer_lines.size()):
		if self.on_line(start_point.x, start_point.y, outer_lines[i][0], outer_lines[i][1]):
			outer_start_index = i
			if outer_end_index != -1:
				break
		if self.on_line(end_point.x, end_point.y, outer_lines[i][0], outer_lines[i][1]):
			outer_end_index = i
			if outer_start_index != -1:
				break
	assert(outer_start_index != -1 && outer_end_index != -1)
	
	for al in inner_lines:
		assert(is_path_element_valid(al))

	var loop_1 : Array = inner_lines.duplicate(true)
	var loop_2 : Array = inner_lines.duplicate(true)
	
	if outer_start_index != outer_end_index:
		if inner_lines.back()[1] != outer_lines[outer_end_index][1]:
			loop_1.append([inner_lines.back()[1], outer_lines[outer_end_index][1]])
			assert(is_path_element_valid(loop_1.back()))
		#else:
		#	loop_1 = hack_consolidate_neighbors(loop_1)
		var l1 : int = (outer_end_index + 1) % outer_lines.size()
		while l1 != outer_start_index:
			loop_1.append(outer_lines[l1])
			assert(is_path_element_valid(loop_1.back()))
			l1 = (l1 + 1) % outer_lines.size()
		if outer_lines[outer_start_index][0] != inner_lines.front()[0]:
			loop_1.append([outer_lines[outer_start_index][0], inner_lines.front()[0]])
			assert(is_path_element_valid(loop_1.back()))
		#else:
		loop_1 = hack_consolidate_neighbors(loop_1)
		assert(is_path_valid(loop_1))

		if inner_lines.back()[1] != outer_lines[outer_end_index][0]:
			loop_2.append([inner_lines.back()[1], outer_lines[outer_end_index][0]])
			assert(is_path_element_valid(loop_2.back()))
		#else:
		#	loop_2 = hack_consolidate_neighbors(loop_2)
		var l2 : int = (outer_end_index + outer_lines.size() - 1) % outer_lines.size()
		while l2 != outer_start_index:
			# TODO: We shouldn't be reversing the outer_lines, we should instead be reversing the inner_lines
			# That way we will preserve always being the same rotation (clockwise/counterclockwise)
			loop_2.append([outer_lines[l2][1], outer_lines[l2][0]])
			assert(is_path_element_valid(loop_2.back()))
			l2 = (l2 + outer_lines.size() - 1) % outer_lines.size()
		if outer_lines[outer_start_index][1] != inner_lines.front()[0]:
			loop_2.append([outer_lines[outer_start_index][1], inner_lines.front()[0]])
			assert(is_path_element_valid(loop_2.back()))
		#else:
		loop_2 = hack_consolidate_neighbors(loop_2)
		loop_2 = hack_reverse_loop(loop_2)
		assert(is_path_valid(loop_2))
	else:
		# The player looped back onto the same line they started from, so the
		# first loop is simple, we just close off the inner path to make it a loop.
		if inner_lines.back()[1] != inner_lines.front()[0]: # player could possibly loop exactly back to starting point on a corner
			loop_1.append([inner_lines.back()[1], inner_lines.front()[0]])
		assert(is_path_element_valid(loop_1.back()))
		if get_signed_area_of_path(loop_1) < 0:
			loop_1 = hack_reverse_loop(loop_1)
		loop_1 = hack_consolidate_neighbors(loop_1)
		assert(is_path_valid(loop_1))

		# The other loop encorporates the entire outer_lines, except for the slice we took out
		var inner_end_to_outer_end : Vector2i = (inner_lines.back()[1] - outer_lines[outer_start_index][1]);
		var inner_start_to_outer_end : Vector2i = (inner_lines.front()[0] - outer_lines[outer_start_index][1]);
		if inner_end_to_outer_end.length_squared() < inner_start_to_outer_end.length_squared():
			# The end of the inner loop is closer to the end of the line segment we're attached to
			if inner_lines.back()[1] != outer_lines[outer_start_index][1]:
				loop_2.append([inner_lines.back()[1], outer_lines[outer_start_index][1]])
				assert(is_path_element_valid(loop_2.back()))
			var l : int = (outer_start_index + 1) % outer_lines.size()
			while l != outer_start_index:
				loop_2.append(outer_lines[l])
				assert(is_path_element_valid(loop_2.back()))
				l = (l + 1) % outer_lines.size()
			if outer_lines[outer_start_index][0] != inner_lines.front()[0]:
				loop_2.append([outer_lines[outer_start_index][0], inner_lines.front()[0]])
				assert(is_path_element_valid(loop_2.back()))
			#else:
			loop_2 = hack_consolidate_neighbors(loop_2)
			assert(is_path_valid(loop_2))
		else:
			# The start of the inner loop is closer to the end of the line segment we're attached to so
			# the end of the inner loop must be closer to the start of the line segment we're attached to
			if inner_lines.back()[1] != outer_lines[outer_start_index][0]:
				loop_2.append([inner_lines.back()[1], outer_lines[outer_start_index][0]])
				assert(is_path_element_valid(loop_2.back()))
			var l : int = (outer_start_index + outer_lines.size() - 1) % outer_lines.size()
			while l != outer_start_index:
				# TODO: We shouldn't be reversing the outer_lines, we should instead be reversing the inner_lines
				# That way we will preserve always being the same rotation (clockwise/counterclockwise)
				loop_2.append([outer_lines[l][1], outer_lines[l][0]])
				assert(is_path_element_valid(loop_2.back()))
				l = (l + outer_lines.size() - 1) % outer_lines.size()
			if outer_lines[outer_start_index][1] != inner_lines.front()[0]:
				loop_2.append([outer_lines[outer_start_index][1], inner_lines.front()[0]])
				assert(is_path_element_valid(loop_2.back()))
			#else:
			loop_2 = hack_consolidate_neighbors(loop_2)
			loop_2 = hack_reverse_loop(loop_2)
			assert(is_path_valid(loop_2))
			
	return [loop_1, loop_2]

func path_to_rect(path : Array) -> Rect2i:
	return Rect2i(Vector2i(min(path[0][0].x, path[1][1].x), min(path[0][0].y, path[1][1].y)), Vector2i(abs(path[0][0].x - path[1][1].x), abs(path[0][0].y - path[1][1].y)))
func rect_to_path(rect : Rect2i) -> Array:
	return [
		[rect.position, rect.position + Vector2i(rect.size.x, 0)],
		[rect.position + Vector2i(rect.size.x, 0), rect.end],
		[rect.end, rect.position + Vector2i(0, rect.size.y)],
		[rect.position + Vector2i(0, rect.size.y), rect.position]
	]

func get_signed_area_of_path(path : Array) -> float:
	var total : int = 0
	for i in range(0, path.size()):
		#var next : int = (i + 1) % path.size()
		var v : int = path[i][0].x * path[i][1].y - path[i][1].x * path[i][0].y
		total += v
	return total / 2.0

func is_path_element_valid(path_el : Array) -> bool:
	var start : Vector2i = path_el[0]
	var end : Vector2i = path_el[1]
	if start == end:
		print("Path Element Invalid: Start & End are same point %s" % [start])
		return false
	if start.x != end.x && start.y != end.y:
		print("Path Element Invalid: Start & End don't share either X or Y coordinates: %s %s" % [start, end])
		return false
	return true

func is_path_valid(path : Array) -> bool:
	var retVal : bool = true
	var area : int = measure_area(path)
	if area == 0:
		print("Path invalid: No area")
		retVal = false
	var signed_area : float = get_signed_area_of_path(path)
	if area != abs(signed_area):
		print("Path invalid: Area(%s) and signed Area(%s) don't agree on size" % [area, signed_area])
		retVal = false
	if signed_area < 0:
		print("Path Invalid: Path is counter-clockwise")
		retVal = false
	for i in range(0, path.size()):
		var n : int = (i + 1) % path.size()
		if path[i][1] != path[n][0]:
			print("Path invalid: elements #%d=%s and #%d=%s are not connected" % [i, path[i], n, path[n]])
			retVal = false
		if are_path_elements_same_axis(path[i], path[n]):
			print("Path invalid: neighbor elements %s and %s are on the same axis" % [path[i], path[n]])
			retVal = false
		for j in range(i + 1, path.size()):
			if do_path_elements_overlap(path[i], path[j]):
				print("Path invalid: two elements overlap: %s and %s" % [path[i], path[n]])
				retVal = false
	return retVal

func do_any_path_elements_overlap(path : Array) -> bool:
	for i in range(0, path.size()):
		for j in range(i + 1, path.size()):
			if do_path_elements_overlap(path[i], path[j]):
				return true
	return false	

func do_ranges_overlap(range_a : Array, range_b : Array) -> bool:
	if abs(range_a[0] - range_a[1]) < abs(range_b[0] - range_b[1]):
		return is_point_in_range(range_a[0], range_b, false) || is_point_in_range(range_a[1], range_b, false)
	else:
		return is_point_in_range(range_b[0], range_a, false) || is_point_in_range(range_b[1], range_a, false)
	
func is_point_in_range(point : int, r : Array, excludeRangeEndPoints : bool) -> bool:
	if excludeRangeEndPoints:
		if r[0] < r[1]:
			return (r[0] + 1) <= point && point <= (r[1] - 1);
		else:
			return (r[1] + 1) <= point && point <= (r[0] - 1);
	else:
		if r[0] < r[1]:
			return r[0] <= point && point <= r[1];
		else:
			return r[1] <= point && point <= r[0];

func do_path_elements_overlap(path_el_a : Array, path_el_b : Array) -> bool:
	var is_a_on_x : bool = is_path_element_on_x_axis(path_el_a)
	var is_b_on_x : bool = is_path_element_on_x_axis(path_el_b)
	if is_a_on_x == is_b_on_x:
		if is_a_on_x: # both on x axis
			if path_el_a[0].x != path_el_b[0].x:
				return false
			if do_ranges_overlap([path_el_a[0].y, path_el_a[1].y], [path_el_b[0].y, path_el_b[1].y]):
				return true
			return false
		else: # both on y axis
			if path_el_a[0].y != path_el_b[0].y:
				return false
			if do_ranges_overlap([path_el_a[0].x, path_el_a[1].x], [path_el_b[0].x, path_el_b[1].x]):
				return true
			return false
	else:
		if is_a_on_x: # a is x-axis, b is y-axis
			var a_is_within_b : bool = is_point_in_range(path_el_a[0].x, [path_el_b[0].x, path_el_b[1].x], true)
			var b_is_within_a : bool = is_point_in_range(path_el_b[0].y, [path_el_a[0].y, path_el_a[1].y], true)
			if a_is_within_b && b_is_within_a:
				return true
			return false
		else: # a is on y-axis, b is on x-axis
			var a_is_within_b : bool = is_point_in_range(path_el_a[0].y, [path_el_b[0].y, path_el_b[1].y], true)
			var b_is_within_a : bool = is_point_in_range(path_el_b[0].x, [path_el_a[0].x, path_el_a[1].x], true)
			if a_is_within_b && b_is_within_a:
				return true
			return false

func are_path_elements_same_axis(path_el_a : Array, path_el_b : Array) -> bool:
	var is_a_on_x : bool = is_path_element_on_x_axis(path_el_a)
	var is_b_on_x : bool = is_path_element_on_x_axis(path_el_b)
	return is_a_on_x == is_b_on_x

func is_path_element_on_x_axis(path_el : Array) -> bool:
	return path_el[0].x == path_el[1].x

func break_out_square(path : Array) -> Array: # square, then remaining path
	#var clockwise : bool = get_signed_area_of_path(path) > 0
	assert(is_path_valid(path))
	for i in range(0, path.size()):
		assert(is_path_element_valid(path[i]))
		var prev : int = (i + path.size() - 1) % path.size()
		assert(path[prev][1] == path[i][0])
		var next : int = (i + 1) % path.size()
		if path[i][0].x == path[i][1].x:
			var delta_x_prev : int = path[prev][0].x - path[prev][1].x
			var delta_x_next : int = path[next][1].x - path[next][0].x
			if delta_x_prev * delta_x_next > 0:
				# They're both aimed in the same direction
				var rect : Rect2i
				var miny : int = min(path[i][0].y, path[i][1].y)
				var height : int = abs(path[i][1].y - path[i][0].y)
				var shorter_path : Array = []
				if abs(delta_x_prev) < abs(delta_x_next):
					# previous is the shorter arm
					var minx : int = min(path[prev][0].x, path[prev][1].x)
					var width : int = abs(delta_x_prev)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var prevprev : int = (i + path.size() - 2) % path.size()
					var new_loc_on_next : Vector2i = Vector2i(path[prev][0].x, path[next][0].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == prev:
							continue
						elif j == prevprev:
							if new_loc_on_next != path[j][0]:
								shorter_path.append([path[j][0], new_loc_on_next])
								assert(is_path_element_valid(shorter_path.back()))
							else:
								print("Omitted %s" % new_loc_on_next)
						elif j == next:
							if new_loc_on_next != path[j][1]:
								shorter_path.append([new_loc_on_next, path[j][1]])
								assert(is_path_element_valid(shorter_path.back()))
							else:
								print("Omitted %s" % new_loc_on_next)
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				else:
					# next is the shorter arm
					var minx : int = min(path[next][0].x, path[next][1].x)
					var width : int = abs(delta_x_next)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var nextnext : int = (i + 2) % path.size()
					var new_loc_on_prev : Vector2i = Vector2i(path[next][1].x, path[prev][0].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == next:
							continue
						elif j == nextnext:
							if new_loc_on_prev != path[j][1]:
								shorter_path.append([new_loc_on_prev, path[j][1]])
								assert(is_path_element_valid(shorter_path.back()))
							else:
								print("Omitted %s" % new_loc_on_prev)
						elif j == prev:
							if new_loc_on_prev != path[j][0]:
								shorter_path.append([path[j][0], new_loc_on_prev])
								assert(is_path_element_valid(shorter_path.back()))
							else:
								print("Omitted %s" % new_loc_on_prev)
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				if !do_any_path_elements_overlap(shorter_path):
					# There's probably a faster way to detect this with dot products and knowing if the
					# polygon is clockwise or counterclockwise... but for now make sure the rect and
					# new path's area equals the path of the old area... otherwise we're adding space
					# rather than dividing.
					var area_of_two_parts = rect.get_area() + measure_area(shorter_path)
					if area_of_two_parts == measure_area(path):
						assert(is_path_valid(shorter_path))
						return [rect_to_path(rect), shorter_path]
		else: # Y Aligned
			var delta_y_prev : int = path[prev][0].y - path[prev][1].y
			var delta_y_next : int = path[next][1].y - path[next][0].y
			if delta_y_prev * delta_y_next > 0:
				# They're both aimed in the same direction
				var rect : Rect2i
				var minx : int = min(path[i][0].x, path[i][1].x)
				var width : int = abs(path[i][1].x - path[i][0].x)
				var shorter_path : Array = []
				if abs(delta_y_prev) < abs(delta_y_next):
					# previous is the shorter arm
					var miny : int = min(path[prev][0].y, path[prev][1].y)
					var height : int = abs(delta_y_prev)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var prevprev : int = (i + path.size() - 2) % path.size()
					var new_loc_on_next : Vector2i = Vector2i(path[next][0].x, path[prev][0].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == prev:
							continue
						elif j == prevprev:
							assert(new_loc_on_next != path[j][0])
							shorter_path.append([path[j][0], new_loc_on_next])
							assert(is_path_element_valid(shorter_path.back()))
						elif j == next:
							assert(new_loc_on_next != path[j][1])
							shorter_path.append([new_loc_on_next, path[j][1]])
							assert(is_path_element_valid(shorter_path.back()))
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				else:
					# next is the shorter arm
					var miny : int = min(path[next][0].y, path[next][1].y)
					var height : int = abs(delta_y_next)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var nextnext : int = (i + 2) % path.size()
					var new_loc_on_prev : Vector2i = Vector2i(path[prev][0].x, path[next][1].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == next:
							continue
						elif j == nextnext:
							assert(new_loc_on_prev != path[j][1])
							shorter_path.append([new_loc_on_prev, path[j][1]])
							assert(is_path_element_valid(shorter_path.back()))
						elif j == prev:
							assert(new_loc_on_prev != path[j][0])
							shorter_path.append([path[j][0], new_loc_on_prev])
							assert(is_path_element_valid(shorter_path.back()))
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				if !do_any_path_elements_overlap(shorter_path):
					# There's probably a faster way to detect this with dot products and knowing if the
					# polygon is clockwise or counterclockwise... but for now make sure the rect and
					# new path's area equals the path of the old area... otherwise we're adding space
					# rather than dividing.
					var area_of_two_parts = rect.get_area() + measure_area(shorter_path)
					if area_of_two_parts == measure_area(path):
						assert(is_path_valid(shorter_path))
						return [rect_to_path(rect), shorter_path]
	print(str(path))
	assert(false, "we should always find something")
	return []

func cleanup_path(path : Array) -> Array:
	for i in range(0, path.size()):
		var n : int = (i + 1) % path.size()
		var same_x : bool = (path[i][0].x == path[i][1].x) && (path[i][1].x == path[n][1].x)
		var same_y : bool = (path[i][0].y == path[i][1].y) && (path[i][1].y == path[n][1].y)
		if same_x || same_y:
			var retVal : Array = []
			for j in range(0, path.size()):
				if i == j:
					continue
				if j == n:
					retVal.append([path[j][0], path[n][1]])
				else:
					retVal.append(path[j])
			return retVal
	return path

func score_loop(path : Array) -> void:
	while path.size() > 4:
		var p : Array = break_out_square(path)
		path = p[1]
		completed_rects.append(path_to_rect(p[0]))
	assert(path.size() == 4)
	completed_rects.append(path_to_rect(path))

func complete_loop(x : int, y : int) -> void:
	if does_extend_line(x, y, inner_lines.back()[0], inner_lines.back()[1]):
		inner_lines.back()[1] = Vector2i(x, y)
	else:
		inner_lines.append([player_pos, Vector2i(x, y)])
	player_pos = Vector2i(x, y)
	var two_loops : Array = create_both_loops()
	var loop_1_area : int = measure_area(two_loops[0])
	var loop_2_area : int = measure_area(two_loops[1])
	#print("%s + %s = %s" % [loop_1_area, loop_2_area, loop_1_area + loop_2_area])
	if loop_1_area < loop_2_area:
		area_covered += loop_1_area
		score_loop(two_loops[0])
		outer_lines = two_loops[1]
	else:
		area_covered += loop_2_area
		score_loop(two_loops[1])
		outer_lines = two_loops[0]
	play_player_area_capture()
	progress_bar.value = round(area_covered * 100.0 / float(area_needed))
	inner_lines = []
	player_on_outer_lines = true
	player_travel_speaker.stop()

func move_if_possible(x : int, y : int) -> bool: # returns true if we can continue calling this
	if abs(player_pos.x - x) > 1 || abs(player_pos.y - y) > 1:
		assert(false)
		assert_color = true
	if player_on_outer_lines:
		if is_on_outer_line(x, y):
			player_pos = Vector2i(x, y)
			return true
		return false
	# Process building new inner line
	if is_on_outer_line(x, y):
		# completed area
		complete_loop(x, y)
		return false
	if is_on_inner_line(x, y):
		if perk_inner_loop_protection != InnerLoopProtection.FULL:
			on_player_death()
		return false
	if does_extend_line(x, y, inner_lines.back()[0], inner_lines.back()[1]):
		inner_lines.back()[1] = Vector2i(x, y)
		player_pos = Vector2i(x, y)
		return true
	inner_lines.append([player_pos, Vector2i(x, y)])
	player_pos = Vector2i(x, y)
	return true

var score : float = 0
var unspent_score : float = 0
func update_score() -> void:
	var frac : float = float(area_covered) / float(area_needed)
	if frac > 1.0:
		# We reward the player more for completing extra area
		frac -= 1.0
		frac *= 3.0
		frac += 1.0
	
	# base points is 1000
	var old_score = score
	score += (frac * 1000.0 * score_multiplier)
	unspent_score += (frac * 1000.0 * score_multiplier)
	while unspent_score >= points_until_next_unlock_credit:
		unspent_score -= points_until_next_unlock_credit
		points_until_next_unlock_credit *= increase_in_unlock_cost_per_unlock
		unlocks_available += 1
	var tween = get_tree().create_tween()
	tween.tween_method(set_score_label, old_score, score, 2).set_trans(Tween.TRANS_SINE)

func set_score_label(value : float) -> void:
	score_value_label.text = "%7.2f" % [round(value * 10) / 10.0]

func switch_player_state(new_state : PlayerState) -> void:
	if new_state == PlayerState.PLAYING:
		if player_state == PlayerState.DEAD || player_state == PlayerState.UNINITIALIZED:
			score = 0
		player_state = new_state
		resume_game()
		return

	if new_state == PlayerState.DEAD:
		update_score()
		game_state_label.text = "Game Over"
		restart_label.text = "Play Again"
		difficulty_tier = 0
		player_state = new_state
		show_tab(tab_child_play)
		hide_tab(tab_child_controls)
		setup_config_tab()
		setup_unlock_tab()
		select_tab(tab_child_play, true)
		return
		
	if new_state == PlayerState.WON_PAUSE:
		update_score()
		play_player_victory()
		game_state_label.text = "Nicely Done"
		restart_label.text = "Continue"
		difficulty_tier += 1
		player_state = new_state
		show_tab(tab_child_play)
		hide_tab(tab_child_controls)
		hide_tab(tab_child_config)
		hide_tab(tab_child_unlock)
		select_tab(tab_child_play, true)
		return

func _process(delta: float) -> void:
	if player_state != PlayerState.PLAYING:
		return
		
	if area_covered >= area_needed:
		switch_player_state(PlayerState.WON_PAUSE)
		return
		
	queue_redraw()
	rotate_player += 5.0 * delta
	process_player_input(delta)
	enemy.move_enemy(delta)
	fuze.move_fuze(delta)

func process_player_input(delta : float) -> void:
	if player_on_outer_lines == false:
		# player is burning new path
		process_inner_line_input(delta)
		return
	if process_outer_line_input(delta):
		return
	if Input.is_key_pressed(KEY_SPACE) || draw_button.button_pressed:
		process_inner_path_start()

func start_inner_path(x : int, y : int) -> void:
	assert(inner_lines.is_empty())
	var ix : int = player_pos.x + x
	var iy : int = player_pos.y + y
	if ix < 0 || iy < 0 || ix >= play_field.size.x || iy >= play_field.size.y:
		# Player trying to move outside of playing area
		return

	# Don't let player draw outside remaining area
	var path_el_on_outer_line : Array = get_outer_line_element(player_pos)
	var triangle_of_intent_path : Array = [
		[path_el_on_outer_line[0], player_pos],
		[player_pos, Vector2i(ix, iy)],
		[Vector2i(ix, iy), path_el_on_outer_line[0]]
	]
	if get_signed_area_of_path(triangle_of_intent_path) < 0: # neg is counter clockwise path
		return
	
	if is_in_claimed_area(ix, iy):
		return

	if is_on_outer_line(ix, iy):
		# player trying to jump off one line onto another? Shouldn't happen, but stop it
		print("Shouldn't happen?! Player starting innner line onto outer line")
		return
	player_on_outer_lines = false
	inner_lines.append([player_pos, Vector2i(ix, iy)])
	player_pos = Vector2i(ix, iy)
	player_travel_speaker.play()

func process_inner_path_start() -> void:
	if Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S) || down_button.button_pressed:
		start_inner_path(0, 1);
	elif Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W) || up_button.button_pressed:
		start_inner_path(0, -1);
	elif Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D) || right_button.button_pressed:
		start_inner_path(1, 0);
	elif Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A) || left_button.button_pressed:
		start_inner_path(-1, 0);
	# else player is just holding down space but no direction - that's ok.

func process_inner_line_input(delta : float) -> void:
	if Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S) || down_button.button_pressed:
		add_player_direction(0, delta)
	elif Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W) || up_button.button_pressed:
		add_player_direction(0, -delta)
	elif Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D) || right_button.button_pressed:
		add_player_direction(delta, 0)
	elif Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A) || left_button.button_pressed:
		add_player_direction(-delta, 0)
	else:
		player_travel_speaker.set_pitch_scale(player_stopped_pitch_scale)
	
func process_outer_line_input(delta : float) -> bool:
	if (Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S) || down_button.button_pressed) && is_direction_on_outer_line(0, 1):
		add_player_direction(0, delta)
		return true
	elif (Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W) || up_button.button_pressed) && is_direction_on_outer_line(0, -1):
		add_player_direction(0, -delta)
		return true
	elif (Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D) || right_button.button_pressed) && is_direction_on_outer_line(1, 0):
		add_player_direction(delta, 0)
		return true
	elif (Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A) || left_button.button_pressed) && is_direction_on_outer_line(-1, 0):
		add_player_direction(-delta, 0)
		return true
	return false

#func fancy_draw_line(start : Vector2, end : Vector2, color : Color) -> void:
#	var delta : Vector2 = end - start
#	var inc : float = float(1) / 10
#	for j in range(0, 10):
#		var i = float(j)/10
#		var dcolor = lerp(Color.GREEN, color, i)
#		draw_line(start + i * delta, start + (i + inc) * delta, dcolor)

var rotate_player : float = 0
func _draw() -> void:
	if play_field == null:
		return
		
	var offset : Vector2 = play_field.global_position - self.global_position

	for rect : Rect2i in completed_rects:
		var rect_color : Color = Color.YELLOW
		if assert_color:
			rect_color = Color.DEEP_PINK
		draw_rect(Rect2(rect.position as Vector2 + offset, rect.size), rect_color)

	for line : Array in outer_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.WHITE)
	for line : Array in inner_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.RED)
	
	var player_length : int = 4
	var rp : int = round(rotate_player) as int
	var p_loc : Vector2 = offset + (player_pos as Vector2)
	if rp % 2 == 0:
		draw_line(p_loc - Vector2(player_length, 0), p_loc + Vector2(player_length, 0), Color.BLUE)
		draw_line(p_loc - Vector2(0, player_length), p_loc + Vector2(0, player_length), Color.BLUE)
	elif rp % 2 == 1:
		draw_line(p_loc - Vector2(player_length, player_length), p_loc + Vector2(player_length, player_length), Color.BLUE)
		draw_line(p_loc - Vector2(-player_length, player_length), p_loc + Vector2(-player_length, player_length), Color.BLUE)
	
	enemy.render(offset)
	fuze.render(offset)

func is_in_claimed_area(x : int, y : int) -> bool:
	if x < 0 || y < 0 || x >= play_field.size.x || y >= play_field.size.y:
		return true
	for rect : Rect2i in completed_rects:
		if x >= rect.position.x && x <= rect.end.x:
			if y >= rect.position.y && y <= rect.end.y:
				return true
	return false

#var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
func add_line(start : Vector2i, end : Vector2i) -> void:
	outer_lines.append([start, end])

func get_path_length(path : Array) -> int:
	var dist : int = 0
	for line in path:
		dist += (line[0] - line[1]).length()
	return dist

func half_way_around_outer_line(pos : Vector2i) -> Vector2i:
	assert(is_on_outer_line(pos.x, pos.y))
	for i in range(0, outer_lines.size()):
		if on_line(pos.x, pos.y, outer_lines[i][0], outer_lines[i][1]):
			var dist : int = get_path_length(outer_lines)
			dist /= 2
			var remaining : int = (pos - outer_lines[i][1]).length()
			if dist < remaining:
				# This should never happen, but let's just check to be sure
				var dir : Vector2i = Enemy.get_v2i_direction(outer_lines[i][1] - outer_lines[i][0])
				return dist * dir + pos
			dist -= remaining
			var n : int = i
			while true:
				n = (n + 1) % outer_lines.size()
				var line_length : int = (outer_lines[n][0] - outer_lines[n][1]).length()
				if dist < line_length:
					var dir : Vector2i = Enemy.get_v2i_direction(outer_lines[n][1] - outer_lines[n][0])
					return dist * dir + outer_lines[n][0]
				dist -= line_length
	assert(false)
	return outer_lines[0][0]

func point_opposite_player() -> Vector2i:
	if player_on_outer_lines:
		return half_way_around_outer_line(player_pos)
	else:
		return half_way_around_outer_line(inner_lines.front()[0])

func play_enemy_trapped() -> void:
	enemy_speaker.stream = audio_stream_enemy_trapped
	enemy_speaker.play()

func play_enemy_respawn() -> void:
	enemy_speaker.stream = audio_stream_enemy_resurrection
	enemy_speaker.play()

func play_fuze_respawn() -> void:
	fuze_speaker.stream = audio_stream_fuze_resurrection
	fuze_speaker.play()

func play_player_death() -> void:
	player_event_speaker.stream = audio_stream_player_death
	player_event_speaker.play()

func play_player_area_capture() -> void:
	player_event_speaker.stream = audio_stream_player_area_capture
	player_event_speaker.play()

func play_player_victory() -> void:
	player_event_speaker.stream = audio_stream_player_victory
	player_event_speaker.play()

func select_tab(control_child : Control, tab_bar_visible : bool) -> void:
	var idx = tab_container.get_tab_idx_from_control(control_child)
	tab_container.set_tab_hidden(idx, false)
	tab_container.current_tab = idx;
	tab_container.tabs_visible = tab_bar_visible

func is_tab_currently_selected(control_child : Control) -> bool:
	var idx = tab_container.get_tab_idx_from_control(control_child)
	return tab_container.current_tab == idx

func show_tab(control_child : Control) -> void:
	var idx = tab_container.get_tab_idx_from_control(control_child)
	tab_container.set_tab_hidden(idx, false)

func hide_tab(control_child : Control) -> void:
	var idx = tab_container.get_tab_idx_from_control(control_child)
	tab_container.set_tab_hidden(idx, true)

func resume_game() -> void:
	select_tab(tab_child_controls, false)
	
	inner_lines = []
	completed_rects = []
	outer_lines = []
	
	var pfs : Vector2i = Vector2i(int(play_field.size.x) - 1, int(play_field.size.y) - 1) 
	add_line(Vector2i(0,0), Vector2i(pfs.x, 0))
	add_line(Vector2i(pfs.x, 0), pfs)
	add_line(pfs, Vector2i(0, pfs.y))
	add_line(Vector2i(0, pfs.y), Vector2i(0,0))
	
	progress_bar.value = 0
	area_covered = 0
	area_needed = int(round((play_field.size.x - 1) * (play_field.size.y - 1) * fraction_of_field_needed))
	player_on_outer_lines = true
	player_pos = Vector2(0, play_field.size.y / 2)
	player_forbidden_movement = Vector2i.ZERO
	player_travel_speaker.stop()
	
	if enemy == null:
		enemy = Enemy.new()
		add_child(enemy)
	enemy.init(self, difficulty_tier)
	
	if fuze == null:
		fuze = Fuze.new()
		add_child(fuze)
	fuze.init(self, difficulty_tier)
	
	score_multiplier = 1.0
	if perk_inner_loop_protection == InnerLoopProtection.NONE:
		score_multiplier *= perk_multiple_no_inner_loop_protection
	elif perk_inner_loop_protection == InnerLoopProtection.BACKUP:
		score_multiplier *= perk_multiple_stop_backtracking_inner_loop
	for i in range(0, difficulty_tier):
		score_multiplier *= 1.1
	
	if fraction_of_field_needed >= 0.9:
		score_multiplier *= perk_multiple_ninety_percent_coverage
	elif fraction_of_field_needed >= 0.85:
		score_multiplier *= perk_multiple_eightyfive_percent_coverage
	elif fraction_of_field_needed >= 0.8:
		score_multiplier *= perk_multiple_eighty_percent_coverage
		
	(tab_child_controls.find_child("DifficultyTier") as Label).text = str(difficulty_tier + 1)
	(tab_child_controls.find_child("ScoreMultiplier") as Label).text = "%.2f" % score_multiplier
	
func init_game() -> void:
	# Move these to _ready()
	play_field = find_child("PlayField") as Control
	score_label = find_child("Score") as Label
	tab_container = find_child("TabContainer") as TabContainer
	progress_bar = find_child("Progress") as ProgressBar
	tab_child_controls = tab_container.find_child("Controls") as Control
	tab_child_play = tab_container.find_child("Play") as Control
	tab_child_config = tab_container.find_child("Config") as Control
	tab_child_unlock = tab_container.find_child("Unlock") as Control
	game_state_label = find_child("GameState") as Label
	restart_label = find_child("RestartLabel") as Label
	up_button = find_child("up_button") as Button
	down_button = find_child("down_button") as Button
	right_button = find_child("right_button") as Button
	left_button = find_child("left_button") as Button
	draw_button = find_child("draw_button") as Button
	score_value_label = find_child("Score") as Label
	unlocks_available_label = find_child("UnlocksAvailable") as Label
	build_line_config_section = tab_child_config.find_child("BuildLineConfig")
	build_protection_option_button = build_line_config_section.find_child("OptionButton")
	build_path_backup_button = tab_child_unlock.find_child("UnlockBuildPathReversing") as Button
	build_path_crossing_button = tab_child_unlock.find_child("UnlockBuildPathCrossing") as Button
	build_speed_slow_button = tab_child_unlock.find_child("UnlockSlowBuildMode") as Button
	build_speed_very_slow_button = tab_child_unlock.find_child("UnlockExtraSlowBuildMode") as Button
	build_speed_fast_button = tab_child_unlock.find_child("UnlockFastBuildMode") as Button
	build_speed_very_fast_button = tab_child_unlock.find_child("UnlockExtraFastBuildMode") as Button
	area_covered_config_section = tab_child_config.find_child("AreaCoverNeeded")
	coverage_option_button = area_covered_config_section.find_child("OptionButton")
	cover_eighty_percent_button = tab_child_unlock.find_child("UnlockEightyPercent") as Button
	cover_eightyfive_percent_button = tab_child_unlock.find_child("UnlockEightyFivePercent") as Button
	cover_ninety_percent_button = tab_child_unlock.find_child("UnlockNinetyPercent") as Button
	player_event_speaker = tab_child_controls.find_child("PlayerEventSpeaker") as AudioStreamPlayer
	player_travel_speaker = tab_child_controls.find_child("PlayerTravelSpeaker") as AudioStreamPlayer
	player_travel_speaker.pitch_scale = player_moving_pitch_scale
	enemy_speaker = tab_child_controls.find_child("EnemySpeaker") as AudioStreamPlayer
	fuze_speaker = tab_child_controls.find_child("FuzeSpeaker") as AudioStreamPlayer

	build_protection_option_button.item_selected.connect(on_build_protection_option_button)
	build_path_backup_button.pressed.connect(on_build_path_backup_button)
	build_path_crossing_button.pressed.connect(on_build_path_crossing_button)
	build_speed_slow_button.pressed.connect(on_build_slow_button)
	build_speed_very_slow_button.pressed.connect(on_build_very_slow_button)
	build_speed_fast_button.pressed.connect(on_build_fast_button)
	build_speed_very_fast_button.pressed.connect(on_build_very_fast_button)
	coverage_option_button.item_selected.connect(on_coverage_option_button)
	cover_eighty_percent_button.pressed.connect(on_cover_eighty_percent_button)
	cover_eightyfive_percent_button.pressed.connect(on_cover_eightyfive_percent_button)
	cover_ninety_percent_button.pressed.connect(on_cover_ninety_percent_button)
	
	#(player_travel_speaker.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_PINGPONG
	
	difficulty_tier = 0
	fraction_of_field_needed = 0.75
	play_field.hide() # TODO: Move the drawing code to a script running on the play_field
	
	switch_player_state(PlayerState.PLAYING)

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
	switch_player_state(PlayerState.DEAD)
	player_travel_speaker.stop()
	play_player_death()

func _on_restart_button_up() -> void:
	switch_player_state(PlayerState.PLAYING)
