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
