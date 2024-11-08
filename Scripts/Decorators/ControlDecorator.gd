extends Node

class_name ControlDecorator

@export var loads_after : ControlDecorator = null

signal loading_completed

var target : Control = null
var our_state : StateMachineState = null

# Default Settings
var settings_default = {
	"scale": Vector2.ONE,
	"duration_in_seconds": 0.15,
	"self_modulate": Color.WHITE,
	"transition_type": Tween.TransitionType.TRANS_QUAD,
}
# Hover Settings
var settings_hover = {
	"scale": Vector2.ONE * 1.1,
	"duration_in_seconds": 0.15,
	"self_modulate": Color.WHITE,
	"transition_type": Tween.TransitionType.TRANS_QUAD,
}
# Loading Settings
var settings_loading = {
	"scale": Vector2.ZERO,
	"duration_in_seconds": 0.05,
	"self_modulate": Color(Color.WHITE, 0),
	"transition_type": Tween.TransitionType.TRANS_QUAD,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = get_parent() as Control
	assert(target != null, "{0} does not have a Control as a parent".format([name]))
	target.mouse_entered.connect(on_hover)
	target.mouse_exited.connect(off_hover)
	target.visibility_changed.connect(on_visibility_changed)
	
	our_state = get_our_state(target)
	our_state.state_enter.connect(on_state_entered)
	
	if loads_after != null:
		loads_after.loading_completed.connect(on_load_after_completed)
	
	# Initialize invisible and small
	add_transition("loading", settings_loading, 0.01,  Callable())
	
	call_deferred("setup")

func on_hover() -> void:
	add_transition("hover", settings_hover, settings_hover["duration_in_seconds"], Callable())

func off_hover() -> void:
	if target.visible:
		add_transition("default-off-hover", settings_default, settings_hover["duration_in_seconds"], Callable())

func on_state_entered() -> void:
	add_transition("loading", settings_loading, 0.01, finished_loading)

var appear_dependancy_can_show : bool = false
var appear_dependancy_can_load : bool = false

func handle_appearance(mode_name : String, dur : float) -> void:
	if appear_dependancy_can_load && appear_dependancy_can_show:
		add_transition(mode_name, settings_default, dur * settings_default["duration_in_seconds"], signal_finished_loading)

func on_visibility_changed() -> void:
	appear_dependancy_can_show = target.visible
	if appear_dependancy_can_show:
		#print("%s visibility changed (currently visible=%s) - calling handle_appearance(%s)" % [target.name, target.visible, str(target.scale)])
		handle_appearance("default-made-visible", 5)
	elif appear_dependancy_can_load == true:
		#print("%s visibility changed (currently visible=%s) - shrinking to %s" % [target.name, target.visible, str(settings_loading["scale"])])
		add_transition("vanishing", settings_loading, 0.01, Callable())

func on_load_after_completed() -> void:
	appear_dependancy_can_load = true
	handle_appearance("default-dependancy-loaded", 1)
	#add_transition(, settings_default, settings_default["duration_in_seconds"], signal_finished_loading)

func finished_loading() -> void:
	if loads_after == null:
		appear_dependancy_can_load = true
		handle_appearance("default-state-entered", 1)

var has_ever_loaded : bool = false
func signal_finished_loading() -> void:
	if has_ever_loaded == false:
		has_ever_loaded = true
	loading_completed.emit()

var tween : Tween = null
var callback_after_tween_finished : Callable = Callable()

func invoke_tween_callback() -> void:
	var tmp : Callable = callback_after_tween_finished
	callback_after_tween_finished = Callable()
	#print("callback invoking, %s.scale=%s" % [target.name, str(target.scale)])
	if tmp:
		tmp.call()

func add_transition(mode_name : String, settings, seconds : float, callback : Callable ) -> void:
	#print("Starting transition " + target.name + " to " + mode_name)

	if tween != null && tween.is_running():
		tween.kill()
		if callback_after_tween_finished.is_valid():
			invoke_tween_callback()
	
	callback_after_tween_finished = callback
	
	# In case we're already out of scene when this gets called
	var tree = get_tree()
	if tree != null:
		tween = tree.create_tween()
		tween.tween_property(target, "scale", settings["scale"], seconds).set_trans(settings["transition_type"])
		#print("transitioning from %s.scale=%s to %s.scale=%s in %f seconds because of %s" % [target.name, str(target.scale), target.name, str(settings["scale"]), seconds, mode_name])
		tween.parallel().tween_property(target, "self_modulate", settings["self_modulate"], seconds).set_trans(settings["transition_type"])
		if callback_after_tween_finished.is_valid():
			tween.tween_callback(invoke_tween_callback)
	else:
		print("add_transition(" + mode_name + ") called when " + name + ".get_tree() returned null")

func get_our_state(t) -> StateMachineState:
	while t != null:
		if t is StateMachineState:
			return t as StateMachineState
		t = t.get_parent()
	assert(false, "{0} does not have a StateMachineState as an ancestor".format(name))
	return null

func setup() -> void:
	target.pivot_offset = target.size / 2.0
	settings_default["scale"] = target.scale
	settings_hover["scale"] = target.scale * 1.1
	
