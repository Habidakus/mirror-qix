extends Resource

class_name UserData

@export var highscore_name : String = ""

@export var unlocks_available : int = 0
@export var unspent_score : float = 0
@export var points_until_next_unlock_credit : float = 1000

@export var perk_unlock_allow_backtracking_inner_loop : bool = false
@export var perk_unlock_allow_crossing_inner_loop : bool = false
@export var perk_unlock_eighty_percent_coverage : bool = false
@export var perk_unlock_eightyfive_percent_coverage : bool = false
@export var perk_unlock_ninety_percent_coverage : bool = false

@export var perk_unlock_allow_slow_build : bool = false
@export var perk_unlock_allow_very_slow_build : bool = false
@export var perk_unlock_allow_fast_build : bool = false
@export var perk_unlock_allow_very_fast_build : bool = false

@export var perk_unlock_two_border_fuzes : bool = false

@export var tutorial_config_tab_appears : bool = false
@export var tutorial_unlock_tab_appears : bool = false
@export var tutorial_switch_back_to_play_tab : bool = false
@export var tutorial_cause_of_death_fuze : bool = false
@export var tutorial_cause_of_death_hunter : bool = false
@export var tutorial_cause_of_death_crossing_the_line : bool = false
@export var tutorial_which_one_is_me : bool = false
@export var tutorial_which_one_is_the_fuze : bool = false
@export var tutorial_which_one_is_the_enemy : bool = false
@export var tutorial_trail_protection : bool = false
@export var tutorial_building_with_space_bar : bool = false
@export var tutorial_using_mirror_button : bool = false
@export var tutorial_which_how_to_capture_area : bool = false
@export var tutorial_which_how_to_complete_level : bool = false
@export var tutorial_using_speed_toggles_on_outer_line : bool = false
@export var tutorial_using_speed_toggles_on_inner_line : bool = false
