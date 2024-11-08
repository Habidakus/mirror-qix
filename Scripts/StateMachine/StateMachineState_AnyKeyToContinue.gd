extends StateMachineState

@export var next_state : StateMachineState
@export var time_out_in_seconds : float = -1

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5

var countdown : float = 0

func _process(delta: float) -> void:
	if time_out_in_seconds > 0:
		countdown += delta
		if countdown > time_out_in_seconds:
			leave_state()

func _input(event):
	handle_event(event)
func _unhandled_input(event):
	handle_event(event)

func handle_event(event):
	# We process on "released" instead of pressed because otherwise immediately
	# switching screens could still have the mouse being pressed on some other
	# screen's button.
	if event.is_released():
		if event is InputEventKey:
			leave_state()
		if event is InputEventMouseButton:
			leave_state()

var leave_tween : Tween = null
func leave_state() -> void:
	if fade_out:
		if leave_tween != null && leave_tween.is_running():
			return
		leave_tween = get_tree().create_tween()
		self.modulate = Color(Color.WHITE, 1)
		var destination_color : Color = Color(Color.WHITE, 0)
		leave_tween.tween_property(self, "modulate", destination_color, fade_time)
		await leave_tween.finished
		our_state_machine.switch_state_internal(next_state)
	else:
		our_state_machine.switch_state_internal(next_state)

func enter_state() -> void:
	countdown = 0
	super.enter_state()
	if fade_in:
		self.modulate = Color(Color.WHITE, 0)
		var tween = get_tree().create_tween()
		var destination_color : Color = Color(Color.WHITE, 1)
		tween.tween_property(self, "modulate", destination_color, fade_time)
	
