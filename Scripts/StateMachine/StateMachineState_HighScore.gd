extends StateMachineState

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5

var persistant_user_data : String = "user://qix_user_data.tres"
var user_data : UserData = null
var high_score_grid : Container = null

func _ready() -> void:
	if ResourceLoader.exists(persistant_user_data):
		user_data = ResourceLoader.load(persistant_user_data)
	else:
		user_data = UserData.new()

func _input(event : InputEvent) -> void:
	handle_event(event)

func _unhandled_input(event : InputEvent) -> void:
	handle_event(event)
	
func enter_state() -> void:
	super.enter_state()
	if fade_in:
		self.modulate = Color(Color.WHITE, 0)
		var tween : Tween = get_tree().create_tween()
		var destination_color : Color = Color(Color.WHITE, 1)
		tween.tween_property(self, "modulate", destination_color, fade_time)
	high_score_grid = find_child("HighScoreGrid") as Container
	fetch_scores()

func fetch_scores() -> void:
	var sw_result: Dictionary = await SilentWolf.Scores.get_scores(10).sw_get_scores_complete
	var found : bool = false
	for entry in sw_result.scores:
		if user_data.highscore_name == entry.player_name:
			found = true
		add_score(entry.player_name, entry.score)
	if !found && !user_data.highscore_name.is_empty():
		sw_result = await SilentWolf.Scores.get_top_score_by_player(user_data.highscore_name, 500).sw_top_player_score_complete
		if sw_result.has("top_score"):
			add_score(sw_result.top_score.player_name, sw_result.top_score.score)
		else:
			add_score(user_data.highscore_name, -1)

func add_score(player_name : String, score) -> void:
	var score_label : Label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color.BLACK)
	if score >= 0:
		score_label.text = "%7.2f" % score
	else:
		score_label.text = "unknown"
	high_score_grid.add_child(score_label)
	var name_label : Label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color.BLACK)
	name_label.text = player_name
	high_score_grid.add_child(name_label)

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

func handle_event(event : InputEvent) -> void:
	# We process on "released" instead of pressed because otherwise immediately
	# switching screens could still have the mouse being pressed on some other
	# screen's button.
	if event.is_released():
		if event is InputEventKey:
			leave_state("Menu")
		if event is InputEventMouseButton:
			leave_state("Menu")
