extends Control

class_name StateMachineState

signal state_enter
signal state_exit

var active_process_mode : ProcessMode
var our_state_machine : StateMachine

func init_state(state_machine: StateMachine) -> void:
	active_process_mode = self.process_mode
	our_state_machine = state_machine
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()

func enter_state() -> void:
	self.process_mode = active_process_mode
	self.show()
	state_enter.emit()

func exit_state(_next_state: StateMachineState) -> void:
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()
	state_exit.emit()
