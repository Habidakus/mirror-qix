extends Node

class_name StateMachine

@export var initial_state : StateMachineState = null

var all_states = []
var current_state : StateMachineState = null

func _ready() -> void:
	for child in get_children():
		if child is StateMachineState:
			register_state(child)
	switch_state_internal(initial_state)

func register_state(state: StateMachineState) -> void:
	all_states.append(state);
	state.init_state(self);
	
func switch_state_internal(state: StateMachineState) -> void:
	if current_state != null:
		current_state.exit_state(state)
	current_state = state
	if state != null:
		state.enter_state()

func switch_state(next_state_name: String) -> void:
	for state in all_states:
		if state.name == next_state_name:
			switch_state_internal(state)
			return
	assert(false, "{0} is not a valid state".format([next_state_name]))
