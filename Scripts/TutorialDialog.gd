extends PanelContainer

class_name TutorialDialog

var offset : Vector2 = Vector2(20, 20)
var parent_callback : Callable

func init_to_lower_right(text : String, global_pos : Vector2, callback : Callable) -> void:
	(find_child("Label") as Label).text = text
	self.global_position = global_pos + offset
	call_deferred("set_line_ends")
	parent_callback = callback
	(find_child("Button") as Button).pressed.connect(on_pressed)

func on_pressed() -> void:
	print("Tutorial Pressed")
	parent_callback.call()
	queue_free()

func set_line_ends() -> void:
	var line = find_child("Line2D") as Line2D
	line.points[0] =  -1 * offset
	line.points[1] = self.size / 2
