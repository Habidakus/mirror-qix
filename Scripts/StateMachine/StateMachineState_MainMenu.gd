extends StateMachineState

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5

func init_state(state_machine: StateMachine) -> void:
	active_process_mode = self.process_mode
	our_state_machine = state_machine
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()

func enter_state() -> void:
	super.enter_state()
	if fade_in:
		self.modulate = Color(Color.WHITE, 0)
		var tween = get_tree().create_tween()
		var destination_color : Color = Color(Color.WHITE, 1)
		tween.tween_property(self, "modulate", destination_color, fade_time)

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

func _on_credits_pressed() -> void:
	leave_state("Credits")

func _on_play_pressed() -> void:
	leave_state("Game")
