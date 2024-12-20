extends StateMachineState

class_name PlayState

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5
@export var player_speed_inner : float = 100
@export var player_speed_outer : float = 150
var enter_button_power_build_speed_on : bool = false

enum CauseOfDeath { FUSE, HUNTER, CROSSING_INNER_LINE }
enum PlayerState { PRE_GAME, PLAYING, DEAD, WON_PAUSE, MIRROR_MOVE, MODAL_TUTORIAL }
var player_state : PlayerState = PlayerState.PRE_GAME

enum EnterButtonPower { MIRROR, SLOW_BUILD_SPEED, VERY_SLOW_BUILD_SPEED, FAST_BUILD_SPEED, VERY_FAST_BUILD_SPEED }
var enter_button_power : EnterButtonPower = EnterButtonPower.MIRROR

var mirror_state_cooldown_current : float = 0.0
var mirror_state_cooldown_max : float = 0.75

var enemy : Enemy = null
var fuze : Fuze = null
var outer_lines : Array = []
var inner_lines : Array = []
var completed_rect_collection : RectCollection = RectCollection.new()
var area_covered : int = 0
var area_covered_modifier_because_of_speed : float = 0
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
var unlock_progress_bar : ProgressBar = null
var scoreboard_name_container : Container = null
var scoreboard_name_line : LineEdit = null
var scoreboard_name_submit : Button = null
var player_pos : Vector2i
var player_mirror_start_pos : Vector2i
var player_mirror_end_pos : Vector2i
var player_on_outer_lines : bool = true
var game_state_label : Label = null
var restart_label : Label = null
var difficulty_tier : int = 0
var score_multiplier : float = 1.0
var up_button : Button = null
var down_button : Button = null
var right_button : Button = null
var left_button : Button = null
var space_bar_button : Button = null
var enter_button_button : Button = null
var enter_button_label : Label = null
var enter_button_color_rect : ColorRect = null
var score_value_label : Label = null
var unlocks_available_label : Label = null
var enter_config_section : Control = null
var enter_power_option_button : OptionButton = null
var build_line_config_section : Control = null
var build_protection_option_button : OptionButton = null
var build_path_backup_button : Button = null
var build_path_crossing_button : Button = null
var build_speed_slow_button : Button = null
var build_speed_very_slow_button : Button = null
var build_speed_fast_button : Button = null
var build_speed_very_fast_button : Button = null
var unlock_dual_fuzes_button : Button = null
var unlock_angry_rover_button : Button = null
var area_covered_config_section : Control = null
var coverage_option_button : OptionButton = null
var cover_eighty_percent_button : Button = null
var cover_eightyfive_percent_button : Button = null
var cover_ninety_percent_button : Button = null
var border_enemy_config_section : Control = null
var border_enemy_option_button : OptionButton = null
var hunter_enemy_config_section : Control = null
var hunter_enemy_option_button : OptionButton = null
var show_high_score_list_button : Button = null

var persistant_user_data : String = "user://qix_user_data.tres"
var user_data : UserData = null

var audio_stream_fuze_resurrection : AudioStream = preload("res://Sound/spawn_02.wav")
var audio_stream_enemy_resurrection : AudioStream = preload("res://Sound/spawn_01.wav")
var audio_stream_enemy_trapped : AudioStream = preload("res://Sound/powerup_03.wav")
var audio_stream_player_death : AudioStream = preload("res://Sound/death_01.wav")
var audio_stream_player_victory : AudioStream = preload("res://Sound/powerup_02.wav")
var audio_stream_player_area_capture : AudioStream = preload("res://Sound/hit_01.wav")
var audio_stream_player_mirror_board : AudioStream = preload("res://Sound/resurrection_04.wav")

var enter_button_cooldown : float = 0
var enter_button_max_cooldown : float = 10.0
var mirror_power_cooldown : float = 10.0

var number_of_enemy_border_fuzes : int = 1

var increase_in_unlock_cost_per_unlock : float = 1.75

enum InnerLoopProtection { NONE, FULL, BACKUP }
var perk_inner_loop_protection : InnerLoopProtection = InnerLoopProtection.FULL

enum HunterEnemyType { QIX, ANGRY_ROVER }
var hunter_enemy_type : HunterEnemyType = HunterEnemyType.QIX

# TODO: Organize these into sets of resources
var perk_multiple_stop_backtracking_inner_loop : float = 1.15
var perk_multiple_no_inner_loop_protection : float = 1.25
var perk_multiple_eighty_percent_coverage : float = 1.5
var perk_multiple_eightyfive_percent_coverage : float = 2
var perk_multiple_ninety_percent_coverage : float = 2.75
var perk_multiple_dual_border_fuzes : float = 1.75

var tutorial_packed_scene : PackedScene = preload("res://Scenes/tutorial.tscn")

func dismiss_tutorial_control_tab_appears() -> void:
	user_data.tutorial_config_tab_appears = true

func get_global_pos_of_center_of_tab(control : Control) -> Vector2:
	var tab_bar = tab_container.get_tab_bar()
	var index = tab_container.get_tab_idx_from_control(control)
	var tab_rect : Rect2 = tab_bar.get_tab_rect(index)
	return tab_bar.global_position + tab_rect.position + tab_rect.size / 2
	
func setup_config_tab() -> void:
	if user_data.are_any_configs_unlocked():
		show_tab(tab_child_config)
		if user_data.tutorial_config_tab_appears == false:
			var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
			var pos : Vector2 = get_global_pos_of_center_of_tab(tab_child_config)
			tutorial.init_to_lower_right("Open the config menu to select interesting\nhandicaps for your next game. The harder the\nhandicap, the greater your score will increase.", pos, dismiss_tutorial_control_tab_appears)
			add_child(tutorial)
	else:
		hide_tab(tab_child_config)
		return
	
	if user_data.perk_unlock_allow_backtracking_inner_loop || user_data.perk_unlock_allow_crossing_inner_loop:
		build_line_config_section.show()
		build_protection_option_button.clear()
		build_protection_option_button.add_item("Full protections vs crossing build line", InnerLoopProtection.FULL)
		if perk_inner_loop_protection == InnerLoopProtection.FULL:
			build_protection_option_button.selected = build_protection_option_button.get_item_index(InnerLoopProtection.FULL)
		if user_data.perk_unlock_allow_backtracking_inner_loop:
			build_protection_option_button.add_item("Protection only against backing up", InnerLoopProtection.BACKUP)
			if perk_inner_loop_protection == InnerLoopProtection.BACKUP:
				build_protection_option_button.selected = build_protection_option_button.get_item_index(InnerLoopProtection.BACKUP)
		if user_data.perk_unlock_allow_crossing_inner_loop:
			build_protection_option_button.add_item("No protection against crossing build line", InnerLoopProtection.NONE)
			if perk_inner_loop_protection == InnerLoopProtection.NONE:
				build_protection_option_button.selected = build_protection_option_button.get_item_index(InnerLoopProtection.NONE)
	else:
		build_line_config_section.hide()
		
	var space_bar_config_section : Control = tab_child_config.find_child("SpaceBarConfig")
	space_bar_config_section.hide()
	
	if user_data.perk_unlock_two_border_fuzes:
		border_enemy_config_section.show()
		border_enemy_option_button.clear()
		border_enemy_option_button.add_item("Single boarder fuze", 1)
		border_enemy_option_button.add_item("Dual boarder fuzes (score x%.2f)" % perk_multiple_dual_border_fuzes, 2)
		border_enemy_option_button.selected = border_enemy_option_button.get_item_index(number_of_enemy_border_fuzes)
	else:
		border_enemy_config_section.hide()
	
	if user_data.perk_unlock_angry_rover:
		hunter_enemy_config_section.show()
		hunter_enemy_option_button.clear()
		hunter_enemy_option_button.add_item("Hunted by the Qix", HunterEnemyType.QIX)
		hunter_enemy_option_button.add_item("Hunted by the Angry Rover", HunterEnemyType.ANGRY_ROVER)
		hunter_enemy_option_button.selected = hunter_enemy_option_button.get_item_index(hunter_enemy_type)
	else:
		hunter_enemy_config_section.hide()
	
	if user_data.perk_unlock_allow_slow_build || user_data.perk_unlock_allow_very_slow_build || user_data.perk_unlock_allow_fast_build || user_data.perk_unlock_allow_very_fast_build:
		enter_config_section.show()
		enter_power_option_button.clear()
		enter_power_option_button.add_item("Reverse board", EnterButtonPower.MIRROR)
		if user_data.perk_unlock_allow_slow_build:
			enter_power_option_button.add_item("Toggle Slow Build Speed", EnterButtonPower.SLOW_BUILD_SPEED)
		if user_data.perk_unlock_allow_very_slow_build:
			enter_power_option_button.add_item("Toggle Very Slow Build Speed", EnterButtonPower.VERY_SLOW_BUILD_SPEED)
		if user_data.perk_unlock_allow_fast_build:
			enter_power_option_button.add_item("Toggle Fast Build Speed", EnterButtonPower.FAST_BUILD_SPEED)
		if user_data.perk_unlock_allow_very_fast_build:
			enter_power_option_button.add_item("Toggle Very Fast Build Speed", EnterButtonPower.VERY_FAST_BUILD_SPEED)
		enter_power_option_button.selected = enter_power_option_button.get_item_index(enter_button_power)
	else:
		enter_config_section.hide()
	
	if user_data.perk_unlock_eighty_percent_coverage:
		area_covered_config_section.show()
		coverage_option_button.clear()
		coverage_option_button.add_item("75%", 75)
		coverage_option_button.add_item("80%% (score x%.2f)" % perk_multiple_eighty_percent_coverage, 80)
		if user_data.perk_unlock_eightyfive_percent_coverage:
			coverage_option_button.add_item("85%% (score x%.2f)" % perk_multiple_eightyfive_percent_coverage, 85)
		if user_data.perk_unlock_ninety_percent_coverage:
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

func dismiss_tutorial_unlock_tab_appears() -> void:
	user_data.tutorial_unlock_tab_appears = true

func setup_unlock_tab() -> void:
	var picking_disabled : bool = false
	if user_data.are_any_unlocks_available():
		show_tab(tab_child_unlock)
		if user_data.tutorial_unlock_tab_appears == false:
			var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
			var pos : Vector2 = get_global_pos_of_center_of_tab(tab_child_unlock)
			tutorial.init_to_lower_right("You've earned enough points to\nunlock handicaps. Playing with\na handicap is a little harder,\nbut your score increases faster.", pos, dismiss_tutorial_unlock_tab_appears)
			add_child(tutorial)
	else:
		if is_tab_currently_selected(tab_child_unlock):
			picking_disabled = true
		else:
			hide_tab(tab_child_unlock)
			return

	unlocks_available_label.text = str(user_data.unlocks_available)
	# Build Crossing Protection
	if user_data.perk_unlock_allow_backtracking_inner_loop:
		build_path_backup_button.button_pressed = true
		build_path_backup_button.disabled = true
	else:
		build_path_backup_button.button_pressed = false
		build_path_backup_button.disabled = picking_disabled
	if user_data.perk_unlock_allow_crossing_inner_loop:
		build_path_crossing_button.button_pressed = true
		build_path_crossing_button.disabled = true
	else:
		build_path_crossing_button.button_pressed = false
		build_path_crossing_button.disabled = picking_disabled
	
	# Enemy modifications
	if user_data.perk_unlock_two_border_fuzes:
		unlock_dual_fuzes_button.button_pressed = true
		unlock_dual_fuzes_button.disabled = true
	else:
		unlock_dual_fuzes_button.button_pressed = false
		unlock_dual_fuzes_button.disabled = picking_disabled
	if user_data.perk_unlock_angry_rover:
		unlock_angry_rover_button.button_pressed = true
		unlock_angry_rover_button.disabled = true
	else:
		unlock_angry_rover_button.button_pressed = false
		unlock_angry_rover_button.disabled = picking_disabled
		
	# Build speed unlocks
	if user_data.perk_unlock_allow_slow_build:
		build_speed_slow_button.button_pressed = true
		build_speed_slow_button.disabled = true
		build_speed_very_slow_button.show()
		if user_data.perk_unlock_allow_very_slow_build:
			build_speed_very_slow_button.button_pressed = true
			build_speed_very_slow_button.disabled = true
		else:
			build_speed_very_slow_button.button_pressed = false
			build_speed_very_slow_button.disabled = picking_disabled
		build_speed_fast_button.show()
		if user_data.perk_unlock_allow_fast_build:
			build_speed_fast_button.button_pressed = true
			build_speed_fast_button.disabled = true
			
			build_speed_very_fast_button.show()
			if user_data.perk_unlock_allow_very_fast_build:
				build_speed_very_fast_button.button_pressed = true
				build_speed_very_fast_button.disabled = true
			else:
				build_speed_very_fast_button.button_pressed = false
				build_speed_very_fast_button.disabled = picking_disabled
		else:
			build_speed_fast_button.button_pressed = false
			build_speed_fast_button.disabled = picking_disabled
			build_speed_very_fast_button.hide()
	else:
		build_speed_slow_button.button_pressed = false
		build_speed_slow_button.disabled = picking_disabled
		build_speed_very_slow_button.hide()
		build_speed_fast_button.hide()
		build_speed_very_fast_button.hide()
	
	# coverage
	if !user_data.perk_unlock_eighty_percent_coverage:
		cover_eighty_percent_button.button_pressed = false
		cover_eighty_percent_button.disabled = picking_disabled
		cover_eightyfive_percent_button.hide()
		cover_ninety_percent_button.hide()
	elif !user_data.perk_unlock_eightyfive_percent_coverage:
		cover_eighty_percent_button.button_pressed = true
		cover_eighty_percent_button.disabled = true
		cover_eightyfive_percent_button.show()
		cover_eightyfive_percent_button.button_pressed = false
		cover_eightyfive_percent_button.disabled = picking_disabled
	elif !user_data.perk_unlock_ninety_percent_coverage:
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

func on_enter_power_option_button(index : int) -> void:
	enter_button_power = enter_power_option_button.get_item_id(index) as EnterButtonPower
	if enter_button_power == EnterButtonPower.MIRROR:
		enter_button_label.text = "Mirror Board"
	elif enter_button_power == EnterButtonPower.SLOW_BUILD_SPEED:
		enter_button_label.text = "Toggle Slow Build"
	elif enter_button_power == EnterButtonPower.VERY_SLOW_BUILD_SPEED:
		enter_button_label.text = "Toggle Very Slow Build"
	elif enter_button_power == EnterButtonPower.FAST_BUILD_SPEED:
		enter_button_label.text = "Toggle Fast Build"
	elif enter_button_power == EnterButtonPower.VERY_FAST_BUILD_SPEED:
		enter_button_label.text = "Toggle Very Fast Build"

func on_border_enemy_option_button(index : int) -> void:
	number_of_enemy_border_fuzes = border_enemy_option_button.get_item_id(index)

func on_hunter_enemy_option_button(index : int) -> void:
	hunter_enemy_type = hunter_enemy_option_button.get_item_id(index) as HunterEnemyType

func on_show_high_score_list_button() -> void:
	leave_state("HighScoreList")

func on_build_path_backup_button() -> void:
	if user_data.perk_unlock_allow_backtracking_inner_loop == false:
		user_data.perk_unlock_allow_backtracking_inner_loop = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func on_build_path_crossing_button() -> void:
	if user_data.perk_unlock_allow_crossing_inner_loop == false:
		user_data.perk_unlock_allow_crossing_inner_loop = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func on_cover_eighty_percent_button() -> void:
	if user_data.perk_unlock_eighty_percent_coverage == false:
		user_data.perk_unlock_eighty_percent_coverage = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func on_cover_eightyfive_percent_button() -> void:
	if user_data.perk_unlock_eightyfive_percent_coverage == false:
		user_data.perk_unlock_eightyfive_percent_coverage = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func on_cover_ninety_percent_button() -> void:
	if user_data.perk_unlock_ninety_percent_coverage == false:
		user_data.perk_unlock_ninety_percent_coverage = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func on_build_slow_button() -> void:
	if user_data.perk_unlock_allow_slow_build == false:
		user_data.perk_unlock_allow_slow_build = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()
		
func on_build_very_slow_button() -> void:
	if user_data.perk_unlock_allow_very_slow_build == false:
		user_data.perk_unlock_allow_very_slow_build = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()
		
func on_build_fast_button() -> void:
	if user_data.perk_unlock_allow_fast_build == false:
		user_data.perk_unlock_allow_fast_build = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()
		
func on_build_very_fast_button() -> void:
	if user_data.perk_unlock_allow_very_fast_build == false:
		user_data.perk_unlock_allow_very_fast_build = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func on_unlock_dual_fuzes_button() -> void:
	if user_data.perk_unlock_two_border_fuzes == false:
		user_data.perk_unlock_two_border_fuzes = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func on_unlock_angry_rover_button() -> void:
	if user_data.perk_unlock_angry_rover == false:
		user_data.perk_unlock_angry_rover = true
		user_data.unlocks_available -= 1
		save_user_data()
		setup_config_tab()
		setup_unlock_tab()

func init_state(state_machine: StateMachine) -> void:
	active_process_mode = self.process_mode
	our_state_machine = state_machine
	player_state = PlayerState.PRE_GAME
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
		if enter_button_power_build_speed_on:
			var boost : float = get_enter_button_power_speed_multiple(enter_button_power)
			dx = dx * boost
			dy = dy * boost
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
			if user_data.tutorial_trail_protection == false:
				user_data.tutorial_trail_protection = true
				switch_player_state(PlayerState.MODAL_TUTORIAL)
				var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
				var pos : Vector2 = play_field.global_position + (player_pos as Vector2)
				tutorial.init_left("You have bumped into your own trail.\nIn some advanced modes this would cause you to die,\nbut not this time.", pos, dismiss_how_to_play_tutorial)
				add_child(tutorial)
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
	
	if user_data.tutorial_which_how_to_capture_area == false && !player_on_outer_lines:
		if inner_lines.size() > 1 && distance_between_two_points_on_path(inner_lines, inner_lines[0][1], player_pos) > 50:
			user_data.tutorial_which_how_to_capture_area = true
			switch_player_state(PlayerState.MODAL_TUTORIAL)
			var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
			var pos : Vector2 = play_field.global_position + (player_pos as Vector2)
			tutorial.init_left("Now that you're drawing a line, loop back to\nthe outer white line to capture some area.", pos, dismiss_how_to_play_tutorial)
			add_child(tutorial)

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

static func on_line(x : int, y : int, start : Vector2i, end : Vector2i) -> bool:
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

func does_cross_path_el(start : Vector2i, end : Vector2i, path_el : Array) -> bool:
	if is_path_element_on_x_axis(path_el):
		var starts_right : bool = start.x < path_el[0].x
		var ends_right : bool = end.x < path_el[0].x
		if starts_right == ends_right:
			return false
		var slope : float = (end.y - start.y) / float(end.x - start.x)
		var y_at_line : float = start.y + slope * (path_el[0].x - start.x)
		if path_el[1].y > path_el[0].y:
			return y_at_line <= path_el[1].y && y_at_line >= path_el[0].y
		else:
			return y_at_line <= path_el[0].y && y_at_line >= path_el[1].y
	else:
		var starts_above : bool = start.y > path_el[0].y
		var ends_above : bool = end.y > path_el[0].y
		if starts_above == ends_above:
			return false
		var slope : float = (end.x - start.x) / float(end.y - start.y)
		var x_at_line : float = start.x + slope * (path_el[0].y - start.y)
		if path_el[1].x > path_el[0].x:
			return x_at_line <= path_el[1].x && x_at_line >= path_el[0].x
		else:
			return x_at_line <= path_el[0].x && x_at_line >= path_el[1].x

func does_cross_path(start : Vector2i, end: Vector2i, path : Array) -> bool:
	for line : Array in path:
		if does_cross_path_el(start, end, line):
			return true
	return false

func does_cross_inner_path(start : Vector2i, end : Vector2i) -> bool:
	return does_cross_path(start, end, inner_lines)

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
							if new_loc_on_next != path[j][0]:
								shorter_path.append([path[j][0], new_loc_on_next])
								assert(is_path_element_valid(shorter_path.back()))
						elif j == next:
							if new_loc_on_next != path[j][1]:
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
							if new_loc_on_prev != path[j][1]:
								shorter_path.append([new_loc_on_prev, path[j][1]])
								assert(is_path_element_valid(shorter_path.back()))
						elif j == prev:
							if new_loc_on_prev != path[j][0]:
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

func score_loop(path : Array, draw_speed : float) -> void:
	while path.size() > 4:
		var p : Array = break_out_square(path)
		path = p[1]
		completed_rect_collection.add_rect(path_to_rect(p[0]), draw_speed)
	assert(path.size() == 4)
	completed_rect_collection.add_rect(path_to_rect(path), draw_speed)

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
	
	var boost : float = get_enter_button_power_speed_multiple(enter_button_power)
	if !enter_button_power_build_speed_on:
		boost = 1
	var boost_score_diff : float = 0
	if loop_1_area < loop_2_area:
		area_covered += loop_1_area
		boost_score_diff = (loop_1_area) / boost - loop_1_area
		score_loop(two_loops[0], boost)
		outer_lines = two_loops[1]
	else:
		area_covered += loop_2_area
		boost_score_diff = (loop_2_area) / boost - loop_2_area
		score_loop(two_loops[1], boost)
		outer_lines = two_loops[0]
	play_player_area_capture()
	progress_bar.value = round(area_covered * 100.0 / float(area_needed))
	area_covered_modifier_because_of_speed += boost_score_diff
	inner_lines = []
	player_on_outer_lines = true
	player_travel_speaker.stop()

func move_if_possible(x : int, y : int) -> bool: # returns true if we can continue calling this
	if abs(player_pos.x - x) > 1 || abs(player_pos.y - y) > 1:
		assert(false)
	if fuze.is_this_location_death(x, y):
		on_player_death(CauseOfDeath.FUSE)
		return false
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
			on_player_death(CauseOfDeath.CROSSING_INNER_LINE)
		elif user_data.tutorial_trail_protection == false:
			user_data.tutorial_trail_protection = true
			switch_player_state(PlayerState.MODAL_TUTORIAL)
			var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
			var pos : Vector2 = play_field.global_position + (player_pos as Vector2)
			tutorial.init_left("You have bumped into your own trail. In some unlock\nmodes this would cause you to die, but not this time.\nYou want to connect back to the white border line.", pos, dismiss_how_to_play_tutorial)
			add_child(tutorial)
		return false
	if does_extend_line(x, y, inner_lines.back()[0], inner_lines.back()[1]):
		inner_lines.back()[1] = Vector2i(x, y)
		player_pos = Vector2i(x, y)
		return true
	inner_lines.append([player_pos, Vector2i(x, y)])
	player_pos = Vector2i(x, y)
	return true

var score : float = 0
func update_score() -> void:
	var frac : float = float(area_covered + area_covered_modifier_because_of_speed) / float(area_needed)
	if frac > 1.0:
		# We reward the player more for completing extra area
		frac -= 1.0
		frac *= 3.0
		frac += 1.0
	
	var unlock_progress_start : float = user_data.unspent_score / user_data.points_until_next_unlock_credit
	# base points is 1000
	var old_score = score
	score += (frac * 1000.0 * score_multiplier)
	user_data.unspent_score += (frac * 1000.0 * score_multiplier)
	var unlock_progress_end : float = user_data.unspent_score / user_data.points_until_next_unlock_credit
	while user_data.unspent_score >= user_data.points_until_next_unlock_credit:
		user_data.unspent_score -= user_data.points_until_next_unlock_credit
		user_data.points_until_next_unlock_credit *= increase_in_unlock_cost_per_unlock
		user_data.unlocks_available += 1
		unlock_progress_end = 1
		
	save_user_data()
	
	var tween = get_tree().create_tween()
	tween.tween_method(set_score_label, old_score, score, 2).set_trans(Tween.TRANS_SINE)
	tween.parallel()
	tween.tween_method(set_unlock_progress_bar, unlock_progress_start, unlock_progress_end, 2).set_trans(Tween.TRANS_SINE)

func set_score_label(value : float) -> void:
	score_value_label.text = "%7.2f" % [round(value * 10) / 10.0]

func set_unlock_progress_bar(value : float) -> void:
	unlock_progress_bar.value = 100 * value

func save_highscore() -> void:
	if !user_data.highscore_name.is_empty():
		var metadata : Dictionary = {}
		metadata["hunter"] = HunterEnemyType.keys()[hunter_enemy_type]
		metadata["fuze_count"] = number_of_enemy_border_fuzes
		metadata["coverage"] = round(fraction_of_field_needed * 100)
		metadata["power"] = EnterButtonPower.keys()[enter_button_power]
		metadata["protection"] = InnerLoopProtection.keys()[perk_inner_loop_protection]
		metadata["tier"] = difficulty_tier
		SilentWolf.Scores.save_score(user_data.highscore_name, score, "main", metadata)
		scoreboard_name_container.hide()
		show_high_score_list_button.show()
		return
	scoreboard_name_container.show()
	show_high_score_list_button.hide()

func on_scoreboard_name_submit() -> void:
	var submitted_name : String = scoreboard_name_line.text
	var valid_name : String = ""
	for c : String in submitted_name:
		var ascii : int = c.to_int()
		var v = c
		if ascii < 32 && ascii > 176:
			v = "_"
		elif ascii == 127:
			v = "_"
		elif ascii == 34 || ascii == 39 || ascii == 42 || ascii == 47 || ascii == 60 || ascii == 62 || ascii == 92: 
			v = "_"
		valid_name += v
	
	if valid_name.is_empty():
		scoreboard_name_line.text = ""
		return
	
	user_data.highscore_name = valid_name
	game_state_label.text = "Welcome %s" % user_data.highscore_name
	if save_user_data():
		scoreboard_name_container.hide()
		save_highscore()
		show_high_score_list_button.show()

func save_user_data() -> bool:
	var error : Error = ResourceSaver.save(user_data, persistant_user_data)
	if error != Error.OK:
		print("Failed to save %s: %s" % [persistant_user_data, error_string(error)])
		return false
	return true

func switch_player_state(new_state : PlayerState) -> void:
	if new_state == PlayerState.PLAYING:
		if player_state == PlayerState.DEAD || player_state == PlayerState.PRE_GAME:
			score = 0
		var start_new_level : bool = player_state != PlayerState.MIRROR_MOVE && player_state != PlayerState.MODAL_TUTORIAL
		player_state = new_state
		if start_new_level:
			resume_game()
		return
	
	if new_state == PlayerState.MIRROR_MOVE:
		player_state = new_state
		trigger_mirror_power()
		return
	
	if new_state == PlayerState.MODAL_TUTORIAL:
		player_state = new_state
		return
	
	if new_state == PlayerState.PRE_GAME:
		player_state = new_state
		if !user_data.highscore_name.is_empty():
			scoreboard_name_container.hide()
			game_state_label.text = "Welcome %s" % user_data.highscore_name
		else:
			scoreboard_name_container.show()
			game_state_label.text = "Get Ready"
		restart_label.text = "Start Game"
		show_tab(tab_child_play)
		setup_config_tab()
		setup_unlock_tab()
		select_tab(tab_child_config, true)
		show_high_score_list_button.hide()
		return

	if new_state == PlayerState.DEAD:
		update_score()
		game_state_label.text = "Game Over"
		restart_label.text = "Play Again"
		player_state = new_state
		show_tab(tab_child_play)
		hide_tab(tab_child_controls)
		setup_config_tab()
		setup_unlock_tab()
		save_highscore()
		difficulty_tier = 0
		set_shader_hue(185)
		select_tab(tab_child_play, true)
		return
		
	if new_state == PlayerState.WON_PAUSE:
		update_score()
		play_player_victory()
		game_state_label.text = "Nicely Done"
		restart_label.text = "Continue"
		difficulty_tier += 1
		set_shader_hue((360 + 185 - difficulty_tier * 20) % 360)
		player_state = new_state
		scoreboard_name_container.hide()
		show_tab(tab_child_play)
		hide_tab(tab_child_controls)
		hide_tab(tab_child_config)
		hide_tab(tab_child_unlock)
		select_tab(tab_child_play, true)
		show_high_score_list_button.hide()
		return

func _process(delta: float) -> void:
	if player_state != PlayerState.PLAYING:
		if player_state == PlayerState.MIRROR_MOVE:
			advance_mirroring(delta)
		return
		
	if area_covered >= area_needed:
		switch_player_state(PlayerState.WON_PAUSE)
		return
	
	spam_play_tutorials()
	
	if enter_button_cooldown > 0:
		enter_button_cooldown -= delta
		var r : float = 1.0 - (enter_button_cooldown / enter_button_max_cooldown)
		enter_button_color_rect.color = Color(r / 2, r / 2, r / 2)
		if enter_button_cooldown <= 0:
			enter_button_color_rect.color = Color.WHITE
			enter_button_button.disabled = false
			
	queue_redraw()
	rotate_player += 5.0 * delta
	process_player_input(delta)
	if player_state == PlayerState.PLAYING:
		enemy.move_enemy(delta)
		fuze.move_fuze(delta)

func process_player_input(delta : float) -> void:
	if Input.is_action_just_pressed("power_button") || enter_button_button.button_pressed:
		if process_enter_button(): # if returned true, they're advising us to stop processing this turn
			return
		
	if player_on_outer_lines == false:
		# player is burning new path
		process_inner_line_input(delta)
		return
	if process_outer_line_input(delta):
		return
	if Input.is_key_pressed(KEY_SPACE) || space_bar_button.button_pressed:
		process_inner_path_start()
		return

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

func mirror_path(path : Array) -> Array:
	var reverse_path : Array = []
	for i in range(0, path.size()):
		var j : int = path.size() - (i + 1)
		reverse_path.append([mirror_v2i(path[j][1]), mirror_v2i(path[j][0])])
		assert(is_path_element_valid(reverse_path.back()))
	assert(is_path_valid(reverse_path))
	return reverse_path

func mirror_v2i(pos : Vector2i) -> Vector2i:
	return Vector2i(int(play_field.size.x) - pos.x, pos.y)
	
func trigger_mirror_power() -> void:
	# reverse all the paths
	outer_lines = mirror_path(outer_lines)
	
	# reverse all the blocks
	completed_rect_collection.mirror(self)

	# move the player and all enemies
	enemy.set_pending_mirror_coordinates()
	fuze.set_pending_mirror_coordinates()
	player_mirror_start_pos = player_pos
	player_mirror_end_pos = half_way_around_outer_line(mirror_v2i(player_pos))

	# set cooldown
	enter_button_max_cooldown = mirror_power_cooldown
	enter_button_cooldown = mirror_power_cooldown
	enter_button_button.disabled = true
	enter_button_color_rect.color = Color.BLACK
	
	mirror_state_cooldown_current = mirror_state_cooldown_max
	play_player_mirror()

func advance_mirroring(delta: float) -> void:
	mirror_state_cooldown_current -= delta

	var remaining_fraction : float = mirror_state_cooldown_current / mirror_state_cooldown_max
	if remaining_fraction < 0:
		remaining_fraction = 0
		
	player_pos = Enemy.lerp_v2i(player_mirror_end_pos, player_mirror_start_pos, remaining_fraction)
	completed_rect_collection.set_mirror_pos(remaining_fraction)
	enemy.set_mirror_pos(remaining_fraction)
	fuze.set_mirror_pos(remaining_fraction)

	queue_redraw()

	if mirror_state_cooldown_current <= 0:
		switch_player_state(PlayerState.PLAYING)

func get_enter_button_power_speed_multiple(power : EnterButtonPower) -> float:
	if power == EnterButtonPower.SLOW_BUILD_SPEED:
		return 0.5
	if power == EnterButtonPower.VERY_SLOW_BUILD_SPEED:
		return 1.0 / 3.0
	if power == EnterButtonPower.FAST_BUILD_SPEED:
		return 1.5
	if power == EnterButtonPower.VERY_FAST_BUILD_SPEED:
		return 2
	return 1
		
func toggle_build_speed(power : EnterButtonPower) -> void:
	var can_toggle_slower : bool = false
	if player_on_outer_lines:
		can_toggle_slower = true

	var enter_button_power_speed_multiple : float = get_enter_button_power_speed_multiple(power)
	var toggle_speed_is_a_fast_speed : bool = enter_button_power_speed_multiple > 1.0
	var would_toggle_make_us_slower : bool = toggle_speed_is_a_fast_speed == enter_button_power_build_speed_on

	if !can_toggle_slower && would_toggle_make_us_slower:
		# toggling would slow us down, and we're currently forbidden from going slower
		return
	
	enter_button_power_build_speed_on = !enter_button_power_build_speed_on
	if enter_button_power_build_speed_on:
		if toggle_speed_is_a_fast_speed:
			enter_button_color_rect.color = Color.LIGHT_PINK
		else:
			enter_button_color_rect.color = Color.SADDLE_BROWN
	else:
		enter_button_color_rect.color = Color.WHITE

func is_enter_button_power_speed_related() -> bool:
	return enter_button_power == EnterButtonPower.SLOW_BUILD_SPEED || enter_button_power == EnterButtonPower.VERY_SLOW_BUILD_SPEED || enter_button_power == EnterButtonPower.FAST_BUILD_SPEED || enter_button_power == EnterButtonPower.VERY_FAST_BUILD_SPEED

func process_enter_button() -> bool: # if true, stop processing inputs this tick
	if player_state != PlayerState.PLAYING:
		return true

	if enter_button_power == EnterButtonPower.MIRROR:
		if enter_button_cooldown > 0:
			return false
		if player_on_outer_lines:
			switch_player_state(PlayerState.MIRROR_MOVE)
			return true
	
	if is_enter_button_power_speed_related():
		toggle_build_speed(enter_button_power)
		return false

	assert(false, "Enter Button Power not implemented")
	return false

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

	completed_rect_collection.render(self, offset)

	for line : Array in outer_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.WHITE)
	for line : Array in inner_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.RED)
	
	if player_state == PlayerState.PRE_GAME:
		return
		
	var player_length : int = 4
	var rp : int = round(rotate_player) as int
	var p_loc : Vector2 = offset + (player_pos as Vector2)
	if rp % 2 == 0:
		draw_line(p_loc - Vector2(player_length, 0), p_loc + Vector2(player_length, 0), Color.BLUE)
		draw_line(p_loc - Vector2(0, player_length), p_loc + Vector2(0, player_length), Color.BLUE)
	elif rp % 2 == 1:
		draw_line(p_loc - Vector2(player_length, player_length), p_loc + Vector2(player_length, player_length), Color.BLUE)
		draw_line(p_loc - Vector2(-player_length, player_length), p_loc + Vector2(-player_length, player_length), Color.BLUE)
	
	if enemy != null:
		enemy.render(offset)
	if fuze != null:
		fuze.render(offset)

func is_in_claimed_area(x : int, y : int) -> bool:
	if x < 0 || y < 0 || x >= play_field.size.x || y >= play_field.size.y:
		return true
	return completed_rect_collection.contains(x, y)

#var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
func add_line(start : Vector2i, end : Vector2i) -> void:
	outer_lines.append([start, end])

func get_path_length(path : Array) -> int:
	var dist : int = 0
	for line in path:
		dist += (line[0] - line[1]).length()
	return dist

static func distance_between_two_points_on_path(path : Array, start : Vector2i, end : Vector2i) -> int:
	for i in range(0, path.size()):
		if on_line(start.x, start.y, path[i][0], path[i][1]):
			var dist_start_to_path_end : int = abs(start.x - path[i][1].x) + abs(start.y - path[i][1].y)
			if on_line(end.x, end.y, path[i][0], path[i][1]):
				var dist_end_to_path_end : int = abs(end.x - path[i][1].x) + abs(end.y - path[i][1].y)
				if dist_end_to_path_end <= dist_start_to_path_end:
					return abs(start.x - end.x) + abs(start.y - end.y)
			var total_dist : int = dist_start_to_path_end
			for j in range(1, path.size() + 1):
				var n : int = (i + j) % path.size()
				if on_line(end.x, end.y, path[n][0], path[n][1]):
					var dist_path_start_to_end : int = abs(end.x - path[n][0].x) + abs(end.y - path[n][0].y)
					return total_dist + dist_path_start_to_end
				else:
					total_dist += abs(path[n][1].x - path[n][0].x) + abs(path[n][1].y - path[n][0].y)
	assert(false, "Should never happen")
	return 500 * 4

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

func get_distance_to_player(pos : Vector2i, dir : int) -> int:
	if !is_on_outer_line(pos.x, pos.y):
		print("Not on outer line")
		return 2500
	if player_on_outer_lines:
		if dir > 0:
			return distance_between_two_points_on_path(outer_lines, pos, player_pos)
		else:
			return distance_between_two_points_on_path(outer_lines, player_pos, pos)
	else:
		if dir > 0:
			return distance_between_two_points_on_path(outer_lines, pos, inner_lines.front()[0])
		else:
			return distance_between_two_points_on_path(outer_lines, inner_lines.front()[0], pos)

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

func play_player_mirror() -> void:
	player_event_speaker.stream = audio_stream_player_mirror_board
	player_event_speaker.play()

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
	outer_lines = []
	completed_rect_collection.clear()
	
	if enter_button_power_build_speed_on:
		toggle_build_speed(enter_button_power)
	
	var pfs : Vector2i = Vector2i(int(play_field.size.x) - 1, int(play_field.size.y) - 1) 
	add_line(Vector2i(0,0), Vector2i(pfs.x, 0))
	add_line(Vector2i(pfs.x, 0), pfs)
	add_line(pfs, Vector2i(0, pfs.y))
	add_line(Vector2i(0, pfs.y), Vector2i(0,0))
	
	progress_bar.value = 0
	area_covered = 0
	area_covered_modifier_because_of_speed = 0
	area_needed = int(round((play_field.size.x - 1) * (play_field.size.y - 1) * fraction_of_field_needed))
	player_on_outer_lines = true
	player_pos = Vector2(0, play_field.size.y / 2)
	player_forbidden_movement = Vector2i.ZERO
	player_travel_speaker.stop()

	if enemy != null:
		enemy.queue_free()
		
	if hunter_enemy_type == HunterEnemyType.QIX:
		enemy = EnemyRainbow.new()
	else:
		enemy = EnemyDwarf.new()
	add_child(enemy)
	enemy.init(self, difficulty_tier)
	
	if fuze != null:
		fuze.queue_free()

	if number_of_enemy_border_fuzes == 1:
		fuze = FuzeSingle.new()
	else:
		fuze = FuzePair.new()
	add_child(fuze)
	fuze.init(self, difficulty_tier)
	
	score_multiplier = 1.0
	if perk_inner_loop_protection == InnerLoopProtection.NONE:
		score_multiplier *= perk_multiple_no_inner_loop_protection
	elif perk_inner_loop_protection == InnerLoopProtection.BACKUP:
		score_multiplier *= perk_multiple_stop_backtracking_inner_loop
	for i in range(0, difficulty_tier):
		score_multiplier *= 1.1
	
	if number_of_enemy_border_fuzes > 1:
		score_multiplier *= perk_multiple_dual_border_fuzes
	if fraction_of_field_needed >= 0.9:
		score_multiplier *= perk_multiple_ninety_percent_coverage
	elif fraction_of_field_needed >= 0.85:
		score_multiplier *= perk_multiple_eightyfive_percent_coverage
	elif fraction_of_field_needed >= 0.8:
		score_multiplier *= perk_multiple_eighty_percent_coverage
		
	(tab_child_controls.find_child("DifficultyTier") as Label).text = str(difficulty_tier + 1)
	(tab_child_controls.find_child("ScoreMultiplier") as Label).text = "%.2f" % score_multiplier

func _ready() -> void:
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
	space_bar_button = find_child("SpaceBarButton") as Button
	enter_button_button = find_child("EnterButtonButton") as Button
	enter_button_label = find_child("EnterButtonLabel") as Label
	enter_button_color_rect = find_child("EnterButtonColorRect") as ColorRect
	score_value_label = find_child("Score") as Label
	scoreboard_name_container = find_child("ScoreboardNameContainer") as Container
	scoreboard_name_line = find_child("ScoreboardName") as LineEdit
	scoreboard_name_submit = find_child("EnterNameButton") as Button
	unlocks_available_label = find_child("UnlocksAvailable") as Label
	enter_config_section = tab_child_config.find_child("EnterConfig")
	enter_power_option_button = enter_config_section.find_child("OptionButton")
	build_line_config_section = tab_child_config.find_child("BuildLineConfig")
	build_protection_option_button = build_line_config_section.find_child("OptionButton")
	build_path_backup_button = tab_child_unlock.find_child("UnlockBuildPathReversing") as Button
	build_path_crossing_button = tab_child_unlock.find_child("UnlockBuildPathCrossing") as Button
	build_speed_slow_button = tab_child_unlock.find_child("UnlockSlowBuildMode") as Button
	build_speed_very_slow_button = tab_child_unlock.find_child("UnlockExtraSlowBuildMode") as Button
	build_speed_fast_button = tab_child_unlock.find_child("UnlockFastBuildMode") as Button
	build_speed_very_fast_button = tab_child_unlock.find_child("UnlockExtraFastBuildMode") as Button
	unlock_dual_fuzes_button = tab_child_unlock.find_child("UnlockDualFuzes") as Button
	unlock_angry_rover_button = tab_child_unlock.find_child("UnlockAngryRover") as Button
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
	border_enemy_config_section = tab_child_config.find_child("BorderEnemyConfig")
	border_enemy_option_button = border_enemy_config_section.find_child("OptionButton")
	hunter_enemy_config_section = tab_child_config.find_child("HunterEnemyConfig")
	hunter_enemy_option_button = hunter_enemy_config_section.find_child("OptionButton")
	unlock_progress_bar = tab_child_play.find_child("UnlockProgressBar") as ProgressBar
	show_high_score_list_button = tab_child_play.find_child("ShowHighScoreListButton") as Button

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
	scoreboard_name_submit.pressed.connect(on_scoreboard_name_submit)
	enter_power_option_button.item_selected.connect(on_enter_power_option_button)
	unlock_dual_fuzes_button.pressed.connect(on_unlock_dual_fuzes_button)
	unlock_angry_rover_button.pressed.connect(on_unlock_angry_rover_button)
	border_enemy_option_button.item_selected.connect(on_border_enemy_option_button)
	hunter_enemy_option_button.item_selected.connect(on_hunter_enemy_option_button)
	show_high_score_list_button.pressed.connect(on_show_high_score_list_button)
	
func init_game() -> void:
	if ResourceLoader.exists(persistant_user_data):
		user_data = ResourceLoader.load(persistant_user_data)
	else:
		user_data = UserData.new()
	
	set_unlock_progress_bar(user_data.unspent_score / user_data.points_until_next_unlock_credit)
	
	difficulty_tier = 0
	set_shader_hue(185)
	fraction_of_field_needed = 0.75
	play_field.hide() # TODO: Move the drawing code to a script running on the play_field
	
	if user_data.are_any_configs_unlocked():
		switch_player_state(PlayerState.PRE_GAME)
	else:
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
		reset_background()
		our_state_machine.switch_state(next_state)
	else:
		our_state_machine.switch_state(next_state)
		reset_background()

func set_shader_hue(hue : float) -> void:
	var background = (%Background as ColorRect)
	var shader_material = (background.material as ShaderMaterial)
	var current_color = shader_material.get_shader_parameter("color_a")
	var tween = get_tree().create_tween()
	
	# Frankly I was not expecting the type of "color_a" to change durring the lifetime of the shader
	if current_color is Vector4:
		var vec_to_color : Color = Color(current_color[0], current_color[1], current_color[2], current_color[3])
		tween.tween_method(set_background_shader_color, vec_to_color.h * 360, hue, 1)
	elif current_color is Color:
		tween.tween_method(set_background_shader_color, current_color.h * 360, hue, 1)

func set_background_shader_color(hue: float):
	var background = (%Background as ColorRect)
	var shader_material = (background.material as ShaderMaterial)
	var color : Color = Color.from_hsv(hue / 360, 90.0 / 100, 33.0 / 100, 1)
	shader_material.set_shader_parameter("color_a", Vector4(color.r, color.g, color.b, color.a))

func reset_background() -> void:
	set_shader_hue(185);

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

func dismiss_how_to_play_tutorial() -> void:
	switch_player_state(PlayerState.PLAYING)
	
func spam_play_tutorials() -> void:
	if player_state != PlayerState.PLAYING:
		return
		
	if user_data.tutorial_which_one_is_me == false:
		user_data.tutorial_which_one_is_me = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = play_field.global_position + (player_pos as Vector2)
		tutorial.init_to_lower_right("This is you.\nYou can move along the border using the WASD keys.", pos, dismiss_how_to_play_tutorial)
		add_child(tutorial)
		return
	if user_data.tutorial_building_with_space_bar == false:
		user_data.tutorial_building_with_space_bar = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = play_field.global_position + (player_pos as Vector2)
		tutorial.init_to_lower_right("While on the border you can hit the\nSPACE bar and travel off the border", pos, dismiss_how_to_play_tutorial)
		add_child(tutorial)
		return
	if user_data.tutorial_which_one_is_the_fuze == false && player_on_outer_lines && fuze.get_a_location() != Vector2i.MAX:
		user_data.tutorial_which_one_is_the_fuze = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = play_field.global_position + (fuze.get_a_location() as Vector2)
		tutorial.init_left("This is a fuze. While travelling on the\nborder you must avoid this green opponent.", pos, dismiss_how_to_play_tutorial)
		add_child(tutorial)
		return
	if user_data.tutorial_which_one_is_the_enemy == false && !player_on_outer_lines:
		if enemy.is_alive():
			var dist_from_enemy_squared : float = enemy.get_distance_from_point_squared(player_pos)
			var inner_path_dist = get_path_length(inner_lines)
			if dist_from_enemy_squared <= 2 * (inner_path_dist * inner_path_dist):
				user_data.tutorial_which_one_is_the_enemy = true
				switch_player_state(PlayerState.MODAL_TUTORIAL)
				var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
				var pos : Vector2 = play_field.global_position + (enemy.get_tutorial_location() as Vector2)
				tutorial.init_left("This is the Qix. While building a\npath to capture area you must not let\nthe Qix hit the path you are drawing.", pos, dismiss_how_to_play_tutorial)
				add_child(tutorial)
				return
	if user_data.tutorial_using_mirror_button == false && enter_button_power == EnterButtonPower.MIRROR:
		if player_on_outer_lines && enter_button_cooldown <= 0 && fuze.get_distance_from_player() < 250:
			user_data.tutorial_using_mirror_button = true
			switch_player_state(PlayerState.MODAL_TUTORIAL)
			var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
			var pos : Vector2 = enter_button_button.global_position + enter_button_button.size / 2
			tutorial.init_left("Your ENTER button is currently set to the mirror power.\nHitting ENTER will reverse the map and all the enemy.\nBut it will place you a little randomly. You can use\nthis power to avoid fuzes.", pos, dismiss_how_to_play_tutorial)
			add_child(tutorial)
			return
	if user_data.tutorial_which_how_to_capture_area == true && user_data.tutorial_which_how_to_complete_level == false && area_covered > 0:
		user_data.tutorial_which_how_to_complete_level = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = progress_bar.global_position + progress_bar.size / 2
		tutorial.init_to_lower_right("As you capture area, you will get closer\nand closer to completing the level.", pos, dismiss_how_to_play_tutorial)
		add_child(tutorial)
		return
	if is_enter_button_power_speed_related() && user_data.tutorial_using_speed_toggles_on_outer_line == false:
		user_data.tutorial_using_speed_toggles_on_outer_line = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = enter_button_button.global_position + enter_button_button.size / 2
		tutorial.init_left("You now have a build speed power slotted.\nAt any time while not building you can\ntap ENTER to switch your build speed.", pos, dismiss_how_to_play_tutorial)
		add_child(tutorial)
		return
	if is_enter_button_power_speed_related() && user_data.tutorial_using_speed_toggles_on_inner_line == false && get_path_length(inner_lines) > 20:
		user_data.tutorial_using_speed_toggles_on_inner_line = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = enter_button_button.global_position + enter_button_button.size / 2
		tutorial.init_left("While building you can only tap ENTER if it will make your\nspeed increase. Completing a build while still moving slow\nwill generate a higher score for the completed area.", pos, dismiss_how_to_play_tutorial)
		add_child(tutorial)
		return
	 

func dismiss_cause_of_death_tutorial() -> void:
	enter_dead_state()
	
func on_player_death(cause_of_death : CauseOfDeath) -> void:
	if cause_of_death == CauseOfDeath.FUSE && user_data.tutorial_cause_of_death_fuze == false:
		user_data.tutorial_cause_of_death_fuze = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = play_field.global_position + (player_pos as Vector2)
		tutorial.init_left("You have died because a fuze\ncaught up with you.", pos, dismiss_cause_of_death_tutorial)
		add_child(tutorial)
	elif cause_of_death == CauseOfDeath.HUNTER && user_data.tutorial_cause_of_death_hunter == false:
		user_data.tutorial_cause_of_death_hunter = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = play_field.global_position + (enemy.get_death_spot() as Vector2)
		tutorial.init_left("You have died because a Qix\nhas reached your build trail.", pos, dismiss_cause_of_death_tutorial)
		add_child(tutorial)
	elif cause_of_death == CauseOfDeath.CROSSING_INNER_LINE && user_data.tutorial_cause_of_death_crossing_the_line == false:
		user_data.tutorial_cause_of_death_crossing_the_line = true
		switch_player_state(PlayerState.MODAL_TUTORIAL)
		var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
		var pos : Vector2 = play_field.global_position + (player_pos as Vector2)
		tutorial.init_left("You have died because you have tragically\ncollided with your own build trail.", pos, dismiss_cause_of_death_tutorial)
		add_child(tutorial)
	else:
		enter_dead_state()

func enter_dead_state() -> void:
	assert(player_state == PlayerState.PLAYING || player_state == PlayerState.MODAL_TUTORIAL)
	switch_player_state(PlayerState.DEAD)
	player_travel_speaker.stop()
	play_player_death()

func _on_restart_button_up() -> void:
	switch_player_state(PlayerState.PLAYING)

func dismiss_tutorial_switch_back_to_play_tab() -> void:
	user_data.tutorial_switch_back_to_play_tab = true
	
func _on_tab_container_tab_selected(tab: int) -> void:
	if user_data != null && user_data.tutorial_switch_back_to_play_tab == false && player_state == PlayerState.DEAD && tab_container.tabs_visible:
		var config_index = tab_container.get_tab_idx_from_control(tab_child_config)
		if tab == config_index:
			var tutorial : TutorialDialog = tutorial_packed_scene.instantiate()
			var pos : Vector2 = get_global_pos_of_center_of_tab(tab_child_play)
			tutorial.init_to_lower_right("Once you've selected which handicaps\nyou want to play with, switch back to\nthe Play tab to launch the next game.", pos, dismiss_tutorial_switch_back_to_play_tab)
			add_child(tutorial)
