extends Object

class_name RectCollection

var rects : Dictionary = {}
var mirror_rects_loc : Dictionary = {}
var mirror_fraction : float = 0

func mirror(play_state : PlayState) -> void:
	mirror_fraction = 1
	mirror_rects_loc.clear()
	for rect in rects.keys():
		var path : Array = play_state.rect_to_path(rect)
		var mp : Array = play_state.mirror_path(path)
		var mr : Rect2i = play_state.path_to_rect(mp)
		mirror_rects_loc[rect] = mr

func set_mirror_pos(remaining_fraction : float) -> void:
	mirror_fraction = remaining_fraction
	if mirror_fraction <= 0:
		var new_rects : Dictionary = {}
		for rect : Rect2i in rects.keys():
			new_rects[mirror_rects_loc[rect]] = rects[rect]
		rects = new_rects
		mirror_rects_loc.clear()

func clear() -> void:
	rects.clear()

func contains(x : int, y : int) -> bool:
	for rect : Rect2i in rects.keys():
		if x >= rect.position.x && x <= rect.end.x:
			if y >= rect.position.y && y <= rect.end.y:
				return true
	return false

func get_color(speed : float) -> Color:
	if speed < 1:
		return Color.SADDLE_BROWN
	elif speed > 1:
		return Color.LIGHT_PINK
	return Color.YELLOW

func get_trans_rect(start : Rect2i, end : Rect2i, offset: Vector2) -> Rect2:
	#var pos : Vector2i = Enemy.lerp_v2i(mirror_rects_loc[rect], rect.position, mirror_fraction)
	var start_center_x : float = start.position.x + start.size.x / 2.0
	var end_center_x : float = end.position.x - end.size.x / 2.0
	var current_center_x : float = lerp(end_center_x, start_center_x, mirror_fraction)

	var size_x : float = start.size.x * 2.0 * abs(mirror_fraction - 0.5)
	var upper_right_pos : Vector2 = Vector2(current_center_x - size_x / 2.0, start.position.y)

	var s : Vector2 = Vector2(size_x, start.size.y)
	return Rect2(upper_right_pos + offset, s)
	
func render(drawer : CanvasItem, offset : Vector2) -> void:
	if mirror_fraction == 0:
	#pos_on_field = Enemy.lerp_v2i(mirror_end_pos, mirror_start_pos, remaining_fraction)
		for rect : Rect2i in rects.keys():
			drawer.draw_rect(Rect2(rect.position as Vector2 + offset, rect.size), get_color(rects[rect]))
	else:
		for rect : Rect2i in rects.keys():
			var trans_rect : Rect2 = get_trans_rect(rect, mirror_rects_loc[rect], offset)
			drawer.draw_rect(trans_rect, get_color(rects[rect]))

func add_rect(rect : Rect2i, draw_speed : float) -> void:
	#assert(path.size() == 4)
	#var r : Rect2i = Rect2i(Vector2i(min(path[0][0].x, path[1][1].x), min(path[0][0].y, path[1][1].y)), Vector2i(abs(path[0][0].x - path[1][1].x), abs(path[0][0].y - path[1][1].y)))
	rects[rect] = draw_speed
