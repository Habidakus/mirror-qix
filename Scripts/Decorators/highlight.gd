extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = get_tree().create_tween()
	var start_color : Color = Color(Color.WHITE, 0)
	var start_scale : Vector2 = Vector2(3.0, 3.0)
	var destination_color : Color = Color(Color.WHITE, 1)
	var destination_scale : Vector2 = Vector2(1.0, 1.0)
	tween.tween_property(self, "scale", start_scale, 0.0)
	tween.tween_property(self, "modulate", start_color, 0.0)
	tween.tween_property(self, "modulate", destination_color, 1.0)
	tween.parallel()
	tween.tween_property(self, "scale", destination_scale, 1.0)
