extends Node

class_name FontSizeDecorator

var target : Control = null
var target_text : String
var text_line : TextLine = TextLine.new()
var font : Font = null
var current_font_size : int = 100

@export var width_padding : float = 5
@export var height_padding : float = 3
@export var max_width : float = -1

var work_to_be_done : bool = false

func _ready() -> void:
	target = get_parent() as Control
	assert(target != null, "{0} does not have a Control as a parent".format([name]))
	#target.resized.connect(on_resize)
	target.item_rect_changed.connect(on_resize)
	assert("text" in target, "{0} does not have the property .text".format([target]))
	font = target.get_theme_default_font()
	current_font_size = target.get_theme_default_font_size()

func _process(_delta: float) -> void:
	#if target_text != target.text:
	#	work_to_be_done = true

	if work_to_be_done:
		call_deferred("adjust_font_size")

func on_resize() -> void:
	print("on_resize=%s" % [target.size])
	work_to_be_done = true

func adjust_font_size() -> void:
	target_text = target.text
	work_to_be_done = false
	var old_size = current_font_size
	calculate_font_size_for_width()
	if current_font_size != old_size:
		print("%s.size=%s %s.parent.size=%s .text=%s .scale=%s .font_size=(%d -> %d)" % [target.name, target.size, target.name, target.get_parent().size, target_text, target.scale, old_size, current_font_size])
		target.add_theme_font_size_override("font_size", current_font_size)
	
func is_font_too_large(font_size : int, width : float, height : float) -> bool:
	assert(font_size > 0)
	var lines = target_text.split("\n")
	if lines.size() == 1:
		text_line.clear()
		text_line.add_string(target_text, font, font_size)
		var text_size : Vector2 = text_line.get_size()
		return (text_size.x > width) || (text_size.y > height)

	#If we happen to have multiple lines, check each line
	for line in lines:
		text_line.clear()
		text_line.add_string(line, font, font_size)
		var text_size : Vector2 = text_line.get_size()
		if (text_size.x > width) || (text_size.y * lines.size() > height):
			return true
	
	return false

func calculate_font_size_for_width() -> void:
	var too_large : int = 450
	var too_small : int = 1
	var l_max_width : float = max(target.custom_minimum_size.x, target.size.x) - width_padding
	var l_max_height : float = max(target.custom_minimum_size.y, target.size.y) - height_padding
	
	if max_width > 0:
		l_max_width = min(max_width - width_padding, l_max_width)
	
	while too_small + 1 < too_large:
		if is_font_too_large(current_font_size, l_max_width, l_max_height):
			too_large = current_font_size
		else:
			too_small = current_font_size
		current_font_size = int(float(too_large + too_small) / float(2))
	
	if current_font_size == 1:
		return
		
	if is_font_too_large(current_font_size, l_max_width, l_max_height):
		current_font_size -= 1
