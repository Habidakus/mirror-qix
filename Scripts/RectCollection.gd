extends Object

class_name RectCollection

var rects : Dictionary = {}

func mirror(play_state : PlayState) -> void:
	var reverse_dict : Dictionary = {}
	for rect in rects.keys():
		var path : Array = play_state.rect_to_path(rect)
		var mp : Array = play_state.mirror_path(path)
		var mr : Rect2i = play_state.path_to_rect(mp)
		reverse_dict[mr] = rects[rect]
	rects = reverse_dict

func clear() -> void:
	rects.clear()

func contains(x : int, y : int) -> bool:
	for rect : Rect2i in rects.keys():
		if x >= rect.position.x && x <= rect.end.x:
			if y >= rect.position.y && y <= rect.end.y:
				return true
	return false

func render(drawer : CanvasItem, offset : Vector2) -> void:
	for rect : Rect2i in rects.keys():
		var rect_color : Color = Color.YELLOW
		var speed : float = rects[rect]
		if speed < 1:
			rect_color = Color.SADDLE_BROWN
		elif speed > 1:
			rect_color = Color.LIGHT_PINK
		drawer.draw_rect(Rect2(rect.position as Vector2 + offset, rect.size), rect_color)

func add_rect(rect : Rect2i, draw_speed : float) -> void:
	#assert(path.size() == 4)
	#var r : Rect2i = Rect2i(Vector2i(min(path[0][0].x, path[1][1].x), min(path[0][0].y, path[1][1].y)), Vector2i(abs(path[0][0].x - path[1][1].x), abs(path[0][0].y - path[1][1].y)))
	rects[rect] = draw_speed
