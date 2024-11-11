extends StateMachineState

@export var fade_in : bool = false
@export var fade_out : bool = false
@export var fade_time : float = 1.5
@export var player_speed : float = 200

var outer_lines : Array = []
var inner_lines : Array = []
var completed_rects : Array = []
var score : int = 0
var play_field : Control = null
var score_label : Label = null
var player_pos : Vector2i
var player_on_outer_lines : bool = true

func init_state(state_machine: StateMachine) -> void:
	active_process_mode = self.process_mode
	our_state_machine = state_machine
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()

var player_movement : Vector2 = Vector2.ZERO
func add_player_direction(dx : float, dy : float) -> void:
	dx = dx * player_speed
	dy = dy * player_speed
	if player_movement == Vector2.ZERO:
		player_movement = Vector2(dx, dy)
		print("Starting movement")
		return
	var m : Vector2 = player_movement * Vector2(dx, dy)
	if m == Vector2.ZERO:
		player_movement = Vector2(dx, dy)
		print("Movement changed axis")
		return
	if m.x < 0 || m.y < 0:
		player_movement = Vector2(dx, dy)
		print("Movement changed direction")
		return
	
	player_movement += Vector2(dx, dy)
	if player_movement.x >= 1:
		move_if_possible(player_pos.x + 1, player_pos.y)
		player_movement.x -= 1
	elif player_movement.y >= 1:
		move_if_possible(player_pos.x, player_pos.y + 1)
		player_movement.y -= 1
	elif player_movement.x <= -1:
		move_if_possible(player_pos.x - 1, player_pos.y)
		player_movement.x += 1
	elif player_movement.y <= -1:
		move_if_possible(player_pos.x, player_pos.y - 1)
		player_movement.y += 1

func on_line(x : int, y : int, start : Vector2i, end : Vector2i) -> bool:
	if start.x == end.x and start.x == x:
		if start.y == y || end.y == y:
			return true;
		var m : float = (start.y - y) * (end.y - y)
		return m < 0
	if start.y == end.y and start.y == y:
		if start.x == x || end.x == x:
			return true;
		var m : float = (start.x - x) * (end.x - x)
		return m < 0
	#assert(false, "Odd line %s to %s" % [start, end])
	return false

func get_outer_line_element(pos : Vector2i) -> Array:
	for line in outer_lines:
		if on_line(pos.x, pos.y, line[0], line[1]):
			return line
	assert(false, "Asked for outer line containing %s, which no line does" % pos)
	return []

func is_on_outer_line(x : int, y : int) -> bool:
	for line in outer_lines:
		if on_line(x, y, line[0], line[1]):
			return true
	return false

func is_on_inner_line(x : int, y : int) -> bool:
	for line in inner_lines:
		if on_line(x, y, line[0], line[1]):
			return true
	return false

func is_direction_on_outer_line(x : int, y : int) -> bool:
	return is_on_outer_line(player_pos.x + x, player_pos.y + y)

func does_extend_line(x : int, y: int, start : Vector2i, end : Vector2i) -> bool:
	if start.x == end.x && start.x == x:
		var dy : int = y - end.y
		if abs(dy) != 1:
			return false
		# ensure we're still going the same direction
		return ((end.y - start.y) * dy) > 0
	if start.y == end.y && start.y == y:
		var dx : int = x - end.x
		if abs(dx) != 1:
			return false
		# ensure we're still going the same direction
		return ((end.x - start.x) * dx) > 0
	return false

func measure_area(lines : Array) -> int:
	# I believe this calucates the area of our polyomino
	var x : int = 0
	var y : int = 0
	var area : int = 0
	for line : Array in lines:
		var start : Vector2i = line[0]
		var end : Vector2i = line[1]
		if end.x > start.x:
			var d : int = (end.x - start.x)
			x += d
			area += d * y
			#print("East line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		elif end.x < start.x:
			var d : int = (start.x - end.x)
			x -= d
			area -= d * y
			#print("West line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		elif end.y > start.y:
			var d : int = (end.y - start.y)
			y += d
			#print("South line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		elif end.y < start.y:
			var d : int = (start.y - end.y)
			y -= d
			#print("North line %s to %s: d = %d, x = %d, y = %d, area = %d" % [start, end, d, x, y, area])
		else:
			assert("what? line = %s to %s" % [start, end])
	if area < 0:
		area = 0 - area
	#print("Area = %s" % [area])
	return area

func hack_consolidate_neighbors(loop: Array) -> Array:
	var mark_for_remove : Array = []
	for i in range(0, loop.size()):
		var n : int = (i + 1) % loop.size()
		if are_path_elements_same_axis(loop[i], loop[n]):
			assert(loop[i][1] == loop[n][0])
			mark_for_remove.append(n)
	if mark_for_remove.is_empty():
		return loop
	var ret_val : Array = []
	for i in range(0, loop.size()):
		var n : int = (i + 1) % loop.size()
		var will_remove_next : bool = mark_for_remove.count(n) > 0
		var will_remove_current : bool = mark_for_remove.count(i) > 0
		assert(will_remove_next == false || will_remove_current == false, "We need to remove two in a row?!")
		if will_remove_next:
			ret_val.append([loop[i][0], loop[n][1]])
		elif !will_remove_current:
			ret_val.append(loop[i])
	return ret_val

func hack_reverse_loop(loop : Array) -> Array:
	var retVal : Array = []
	for i in range(0, loop.size()):
		var n : int = loop.size() - (i + 1)
		retVal.append([loop[n][1], loop[n][0]])
	return retVal

func create_both_loops() -> Array:
	var start_point : Vector2i = inner_lines.front()[0]
	var end_point : Vector2i = inner_lines.back()[1]
	var outer_start_index : int = -1
	var outer_end_index : int = -1
	for i in range(0, outer_lines.size()):
		if self.on_line(start_point.x, start_point.y, outer_lines[i][0], outer_lines[i][1]):
			outer_start_index = i
			if outer_end_index != -1:
				break
		if self.on_line(end_point.x, end_point.y, outer_lines[i][0], outer_lines[i][1]):
			outer_end_index = i
			if outer_start_index != -1:
				break
	assert(outer_start_index != -1 && outer_end_index != -1)
	
	for al in inner_lines:
		assert(is_path_element_valid(al))

	var loop_1 : Array = inner_lines.duplicate(true)
	var loop_2 : Array = inner_lines.duplicate(true)
	
	if outer_start_index != outer_end_index:
		if inner_lines.back()[1] != outer_lines[outer_end_index][1]:
			loop_1.append([inner_lines.back()[1], outer_lines[outer_end_index][1]])
			assert(is_path_element_valid(loop_1.back()))
		#else:
		#	loop_1 = hack_consolidate_neighbors(loop_1)
		var l1 : int = (outer_end_index + 1) % outer_lines.size()
		while l1 != outer_start_index:
			loop_1.append(outer_lines[l1])
			assert(is_path_element_valid(loop_1.back()))
			l1 = (l1 + 1) % outer_lines.size()
		if outer_lines[outer_start_index][0] != inner_lines.front()[0]:
			loop_1.append([outer_lines[outer_start_index][0], inner_lines.front()[0]])
			assert(is_path_element_valid(loop_1.back()))
		#else:
		loop_1 = hack_consolidate_neighbors(loop_1)
		assert(is_path_valid(loop_1))

		if inner_lines.back()[1] != outer_lines[outer_end_index][0]:
			loop_2.append([inner_lines.back()[1], outer_lines[outer_end_index][0]])
			assert(is_path_element_valid(loop_2.back()))
		#else:
		#	loop_2 = hack_consolidate_neighbors(loop_2)
		var l2 : int = (outer_end_index + outer_lines.size() - 1) % outer_lines.size()
		while l2 != outer_start_index:
			# TODO: We shouldn't be reversing the outer_lines, we should instead be reversing the inner_lines
			# That way we will preserve always being the same rotation (clockwise/counterclockwise)
			loop_2.append([outer_lines[l2][1], outer_lines[l2][0]])
			assert(is_path_element_valid(loop_2.back()))
			l2 = (l2 + outer_lines.size() - 1) % outer_lines.size()
		if outer_lines[outer_start_index][1] != inner_lines.front()[0]:
			loop_2.append([outer_lines[outer_start_index][1], inner_lines.front()[0]])
			assert(is_path_element_valid(loop_2.back()))
		#else:
		loop_2 = hack_consolidate_neighbors(loop_2)
		loop_2 = hack_reverse_loop(loop_2)
		assert(is_path_valid(loop_2))
	else:
		# The player looped back onto the same line they started from, so the
		# first loop is simple, we just close off the inner path to make it a loop.
		loop_1.append([inner_lines.back()[1], inner_lines.front()[0]])
		assert(is_path_element_valid(loop_1.back()))
		if get_signed_area_of_path(loop_1) < 0:
			loop_1 = hack_reverse_loop(loop_1)
		assert(is_path_valid(loop_1))

		# The other loop encorporates the entire outer_lines, except for the slice we took out
		var inner_end_to_outer_end : Vector2i = (inner_lines.back()[1] - outer_lines[outer_start_index][1]);
		var inner_start_to_outer_end : Vector2i = (inner_lines.front()[0] - outer_lines[outer_start_index][1]);
		if inner_end_to_outer_end.length_squared() < inner_start_to_outer_end.length_squared():
			# The end of the inner loop is closer to the end of the line segment we're attached to
			loop_2.append([inner_lines.back()[1], outer_lines[outer_start_index][1]])
			assert(is_path_element_valid(loop_2.back()))
			var l : int = (outer_start_index + 1) % outer_lines.size()
			while l != outer_start_index:
				loop_2.append(outer_lines[l])
				assert(is_path_element_valid(loop_2.back()))
				l = (l + 1) % outer_lines.size()
			if outer_lines[outer_start_index][0] != inner_lines.front()[0]:
				loop_2.append([outer_lines[outer_start_index][0], inner_lines.front()[0]])
				assert(is_path_element_valid(loop_2.back()))
			#else:
			loop_2 = hack_consolidate_neighbors(loop_2)
			assert(is_path_valid(loop_2))
		else:
			# The start of the inner loop is closer to the end of the line segment we're attached to so
			# the end of the inner loop must be closer to the start of the line segment we're attached to
			loop_2.append([inner_lines.back()[1], outer_lines[outer_start_index][0]])
			assert(is_path_element_valid(loop_2.back()))
			var l : int = (outer_start_index + outer_lines.size() - 1) % outer_lines.size()
			while l != outer_start_index:
				# TODO: We shouldn't be reversing the outer_lines, we should instead be reversing the inner_lines
				# That way we will preserve always being the same rotation (clockwise/counterclockwise)
				loop_2.append([outer_lines[l][1], outer_lines[l][0]])
				assert(is_path_element_valid(loop_2.back()))
				l = (l + outer_lines.size() - 1) % outer_lines.size()
			if outer_lines[outer_start_index][1] != inner_lines.front()[0]:
				loop_2.append([outer_lines[outer_start_index][1], inner_lines.front()[0]])
				assert(is_path_element_valid(loop_2.back()))
			#else:
			loop_2 = hack_consolidate_neighbors(loop_2)
			loop_2 = hack_reverse_loop(loop_2)
			assert(is_path_valid(loop_2))
			
	return [loop_1, loop_2]

func path_to_rect(path : Array) -> Rect2i:
	return Rect2i(Vector2i(min(path[0][0].x, path[1][1].x), min(path[0][0].y, path[1][1].y)), Vector2i(abs(path[0][0].x - path[1][1].x), abs(path[0][0].y - path[1][1].y)))
func rect_to_path(rect : Rect2i) -> Array:
	return [
		[rect.position, rect.position + Vector2i(rect.size.x, 0)],
		[rect.position + Vector2i(rect.size.x, 0), rect.end],
		[rect.end, rect.position + Vector2i(0, rect.size.y)],
		[rect.position + Vector2i(0, rect.size.y), rect.position]
	]

func get_signed_area_of_path(path : Array) -> float:
	var total : int = 0
	for i in range(0, path.size()):
		#var next : int = (i + 1) % path.size()
		var v : int = path[i][0].x * path[i][1].y - path[i][1].x * path[i][0].y
		total += v
	return total / 2.0

func is_path_element_valid(path_el : Array) -> bool:
	var start : Vector2i = path_el[0]
	var end : Vector2i = path_el[1]
	if start == end:
		print("Path Element Invalid: Start & End are same point %s" % [start])
		return false
	if start.x != end.x && start.y != end.y:
		print("Path Element Invalid: Start & End don't share either X or Y coordinates: %s %s" % [start, end])
		return false
	return true

func is_path_valid(path : Array) -> bool:
	var retVal : bool = true
	var area : int = measure_area(path)
	if area == 0:
		print("Path invalid: No area")
		retVal = false
	var signed_area : float = get_signed_area_of_path(path)
	if area != abs(signed_area):
		print("Path invalid: Area(%s) and signed Area(%s) don't agree on size" % [area, signed_area])
		retVal = false
	if signed_area < 0:
		print("Path Invalid: Path is counter-clockwise")
		retVal = false
	for i in range(0, path.size()):
		var n : int = (i + 1) % path.size()
		if path[i][1] != path[n][0]:
			print("Path invalid: elements #%d=%s and #%d=%s are not connected" % [i, path[i], n, path[n]])
			retVal = false
		if are_path_elements_same_axis(path[i], path[n]):
			print("Path invalid: neighbor elements %s and %s are on the same axis" % [path[i], path[n]])
			retVal = false
		for j in range(i + 1, path.size()):
			if do_path_elements_overlap(path[i], path[j]):
				print("Path invalid: two elements overlap: %s and %s" % [path[i], path[n]])
				retVal = false
	return retVal

func do_any_path_elements_overlap(path : Array) -> bool:
	for i in range(0, path.size()):
		for j in range(i + 1, path.size()):
			if do_path_elements_overlap(path[i], path[j]):
				return true
	return false	

func do_ranges_overlap(range_a : Array, range_b : Array) -> bool:
	if abs(range_a[0] - range_a[1]) < abs(range_b[0] - range_b[1]):
		return is_point_in_range(range_a[0], range_b, false) || is_point_in_range(range_a[1], range_b, false)
	else:
		return is_point_in_range(range_b[0], range_a, false) || is_point_in_range(range_b[1], range_a, false)
	
func is_point_in_range(point : int, r : Array, excludeRangeEndPoints : bool) -> bool:
	if excludeRangeEndPoints:
		if r[0] < r[1]:
			return (r[0] + 1) <= point && point <= (r[1] - 1);
		else:
			return (r[1] + 1) <= point && point <= (r[0] - 1);
	else:
		if r[0] < r[1]:
			return r[0] <= point && point <= r[1];
		else:
			return r[1] <= point && point <= r[0];

func do_path_elements_overlap(path_el_a : Array, path_el_b : Array) -> bool:
	var is_a_on_x : bool = is_path_element_on_x_axis(path_el_a)
	var is_b_on_x : bool = is_path_element_on_x_axis(path_el_b)
	if is_a_on_x == is_b_on_x:
		if is_a_on_x: # both on x axis
			if path_el_a[0].x != path_el_b[0].x:
				return false
			if do_ranges_overlap([path_el_a[0].y, path_el_a[1].y], [path_el_b[0].y, path_el_b[1].y]):
				return true
			return false
		else: # both on y axis
			if path_el_a[0].y != path_el_b[0].y:
				return false
			if do_ranges_overlap([path_el_a[0].x, path_el_a[1].x], [path_el_b[0].x, path_el_b[1].x]):
				return true
			return false
	else:
		if is_a_on_x: # a is x-axis, b is y-axis
			var a_is_within_b : bool = is_point_in_range(path_el_a[0].x, [path_el_b[0].x, path_el_b[1].x], true)
			var b_is_within_a : bool = is_point_in_range(path_el_b[0].y, [path_el_a[0].y, path_el_a[1].y], true)
			if a_is_within_b && b_is_within_a:
				return true
			return false
		else: # a is on y-axis, b is on x-axis
			var a_is_within_b : bool = is_point_in_range(path_el_a[0].y, [path_el_b[0].y, path_el_b[1].y], true)
			var b_is_within_a : bool = is_point_in_range(path_el_b[0].x, [path_el_a[0].x, path_el_a[1].x], true)
			if a_is_within_b && b_is_within_a:
				return true
			return false

func are_path_elements_same_axis(path_el_a : Array, path_el_b : Array) -> bool:
	var is_a_on_x : bool = is_path_element_on_x_axis(path_el_a)
	var is_b_on_x : bool = is_path_element_on_x_axis(path_el_b)
	return is_a_on_x == is_b_on_x

func is_path_element_on_x_axis(path_el : Array) -> bool:
	return path_el[0].x == path_el[1].x

func break_out_square(path : Array) -> Array: # square, then remaining path
	#var clockwise : bool = get_signed_area_of_path(path) > 0
	assert(is_path_valid(path))
	for i in range(0, path.size()):
		assert(is_path_element_valid(path[i]))
		var prev : int = (i + path.size() - 1) % path.size()
		assert(path[prev][1] == path[i][0])
		var next : int = (i + 1) % path.size()
		if path[i][0].x == path[i][1].x:
			var delta_x_prev : int = path[prev][0].x - path[prev][1].x
			var delta_x_next : int = path[next][1].x - path[next][0].x
			if delta_x_prev * delta_x_next > 0:
				# They're both aimed in the same direction
				var rect : Rect2i
				var miny : int = min(path[i][0].y, path[i][1].y)
				var height : int = abs(path[i][1].y - path[i][0].y)
				var shorter_path : Array = []
				if abs(delta_x_prev) < abs(delta_x_next):
					# previous is the shorter arm
					var minx : int = min(path[prev][0].x, path[prev][1].x)
					var width : int = abs(delta_x_prev)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var prevprev : int = (i + path.size() - 2) % path.size()
					var new_loc_on_next : Vector2i = Vector2i(path[prev][0].x, path[next][0].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == prev:
							continue
						elif j == prevprev:
							assert(new_loc_on_next != path[j][0])
							shorter_path.append([path[j][0], new_loc_on_next])
							assert(is_path_element_valid(shorter_path.back()))
						elif j == next:
							assert(new_loc_on_next != path[j][1])
							shorter_path.append([new_loc_on_next, path[j][1]])
							assert(is_path_element_valid(shorter_path.back()))
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				else:
					# next is the shorter arm
					var minx : int = min(path[next][0].x, path[next][1].x)
					var width : int = abs(delta_x_next)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var nextnext : int = (i + 2) % path.size()
					var new_loc_on_prev : Vector2i = Vector2i(path[next][1].x, path[prev][0].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == next:
							continue
						elif j == nextnext:
							assert(new_loc_on_prev != path[j][1])
							shorter_path.append([new_loc_on_prev, path[j][1]])
							assert(is_path_element_valid(shorter_path.back()))
						elif j == prev:
							assert(new_loc_on_prev != path[j][0])
							shorter_path.append([path[j][0], new_loc_on_prev])
							assert(is_path_element_valid(shorter_path.back()))
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				if !do_any_path_elements_overlap(shorter_path):
					# There's probably a faster way to detect this with dot products and knowing if the
					# polygon is clockwise or counterclockwise... but for now make sure the rect and
					# new path's area equals the path of the old area... otherwise we're adding space
					# rather than dividing.
					var area_of_two_parts = rect.get_area() + measure_area(shorter_path)
					if area_of_two_parts == measure_area(path):
						assert(is_path_valid(shorter_path))
						return [rect_to_path(rect), shorter_path]
		else: # Y Aligned
			var delta_y_prev : int = path[prev][0].y - path[prev][1].y
			var delta_y_next : int = path[next][1].y - path[next][0].y
			if delta_y_prev * delta_y_next > 0:
				# They're both aimed in the same direction
				var rect : Rect2i
				var minx : int = min(path[i][0].x, path[i][1].x)
				var width : int = abs(path[i][1].x - path[i][0].x)
				var shorter_path : Array = []
				if abs(delta_y_prev) < abs(delta_y_next):
					# previous is the shorter arm
					var miny : int = min(path[prev][0].y, path[prev][1].y)
					var height : int = abs(delta_y_prev)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var prevprev : int = (i + path.size() - 2) % path.size()
					var new_loc_on_next : Vector2i = Vector2i(path[next][0].x, path[prev][0].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == prev:
							continue
						elif j == prevprev:
							assert(new_loc_on_next != path[j][0])
							shorter_path.append([path[j][0], new_loc_on_next])
							assert(is_path_element_valid(shorter_path.back()))
						elif j == next:
							assert(new_loc_on_next != path[j][1])
							shorter_path.append([new_loc_on_next, path[j][1]])
							assert(is_path_element_valid(shorter_path.back()))
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				else:
					# next is the shorter arm
					var miny : int = min(path[next][0].y, path[next][1].y)
					var height : int = abs(delta_y_next)
					rect = Rect2i(Vector2i(minx, miny), Vector2i(width, height))
					var nextnext : int = (i + 2) % path.size()
					var new_loc_on_prev : Vector2i = Vector2i(path[prev][0].x, path[next][1].y)
					for j in range(0, path.size()):
						if j == i:
							continue
						elif j == next:
							continue
						elif j == nextnext:
							assert(new_loc_on_prev != path[j][1])
							shorter_path.append([new_loc_on_prev, path[j][1]])
							assert(is_path_element_valid(shorter_path.back()))
						elif j == prev:
							assert(new_loc_on_prev != path[j][0])
							shorter_path.append([path[j][0], new_loc_on_prev])
							assert(is_path_element_valid(shorter_path.back()))
						else:
							shorter_path.append(path[j])
							assert(is_path_element_valid(shorter_path.back()))
				if !do_any_path_elements_overlap(shorter_path):
					# There's probably a faster way to detect this with dot products and knowing if the
					# polygon is clockwise or counterclockwise... but for now make sure the rect and
					# new path's area equals the path of the old area... otherwise we're adding space
					# rather than dividing.
					var area_of_two_parts = rect.get_area() + measure_area(shorter_path)
					if area_of_two_parts == measure_area(path):
						assert(is_path_valid(shorter_path))
						return [rect_to_path(rect), shorter_path]
	print(str(path))
	assert(false, "we should always find something")
	return []

# TODO: Needs to be re-written
func break_out_square_old(path : Array) -> Array: # square, then remaining path
	var signed_area = get_signed_area_of_path(path)
	print("signed area = %s" % [signed_area])
	var square : Array = []
	var remaining : Array = []
	for i in range(0, path.size()):
		var q : int = (i + path.size() - 1) % path.size()
		var n : int = (i + 1) % path.size()
		var m : int = (i + 2) % path.size()
		var c1 : Vector2i = path[i][0]
		var f1 : Vector2i = path[i][1]
		var c2 : Vector2i = path[n][1]
		var f2 : Vector2i
		if c1.x == f1.x:
			f2.x = c2.x
			f2.y = c1.y
		else:
			f2.x = c1.x
			f2.y = c2.y
		if on_line(f2.x, f2.y, path[m][0], path[m][1]):
			square = [[c1, f1], [f1, c2], [c2, f2], [f2, c1]]
			for j in range(0, path.size()):
				if j == i:
					# delete this
					continue
				if j == n:
					# delete this
					continue
				if j == q:
					if path[q][0] != f2:
						remaining.append([path[q][0], f2])
					continue
				if j == m:
					if f2 != path[m][1]:
						remaining.append([f2,path[m][1]])
					continue
				remaining.append(path[j])
			return [square, cleanup_path(remaining)]
		# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
		# all of this is dubious? but maybe works?
		c1 = path[n][1]
		f1 = path[n][0]
		c2 = path[i][0]
		if c1.x == f1.x:
			f2.x = c2.x
			f2.y = c1.y
		else:
			f2.x = c1.x
			f2.y = c2.y
		if on_line(f2.x, f2.y, path[q][0], path[q][1]):
			square = [[c1, f1], [f1, c2], [c2, f2], [f2, c1]]
			for j in range(0, path.size()):
				if j == i:
					# delete this
					continue
				if j == n:
					# delete this
					continue
				if j == q:
					if path[q][0] != f2:
						remaining.append([path[q][0], f2])
					continue
				if j == m:
					if f2 != path[m][1]:
						remaining.append([f2,path[m][1]])
					continue
				remaining.append(path[j])
			return [square, cleanup_path(remaining)]
		# END DUBIOUS
		# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	if square.is_empty():
		print("Found no square in path")
		print(str(path))
		assert(false, "Found no square in path")
	return [square, cleanup_path(remaining)]

func cleanup_path(path : Array) -> Array:
	for i in range(0, path.size()):
		var n : int = (i + 1) % path.size()
		var same_x : bool = (path[i][0].x == path[i][1].x) && (path[i][1].x == path[n][1].x)
		var same_y : bool = (path[i][0].y == path[i][1].y) && (path[i][1].y == path[n][1].y)
		if same_x || same_y:
			var retVal : Array = []
			for j in range(0, path.size()):
				if i == j:
					continue
				if j == n:
					retVal.append([path[j][0], path[n][1]])
				else:
					retVal.append(path[j])
			return retVal
	return path

func score_loop(score_inc : int, path : Array) -> void:
	score += score_inc
	while path.size() > 4:
		var p : Array = break_out_square(path)
		path = p[1]
		completed_rects.append(path_to_rect(p[0]))
	assert(path.size() == 4)
	completed_rects.append(path_to_rect(path))

func complete_loop(x : int, y : int) -> void:
	if does_extend_line(x, y, inner_lines.back()[0], inner_lines.back()[1]):
		inner_lines.back()[1] = Vector2i(x, y)
	else:
		inner_lines.append([player_pos, Vector2i(x, y)])
	player_pos = Vector2i(x, y)
	var two_loops : Array = create_both_loops()
	var loop_1_area : int = measure_area(two_loops[0])
	var loop_2_area : int = measure_area(two_loops[1])
	#print("%s + %s = %s" % [loop_1_area, loop_2_area, loop_1_area + loop_2_area])
	if loop_1_area < loop_2_area:
		score_loop(loop_1_area, two_loops[0])
		outer_lines = two_loops[1]
	else:
		score_loop(loop_2_area, two_loops[1])
		outer_lines = two_loops[0]
	score_label.text = str(round(score * 1000 / ((play_field.size.x - 1) * (play_field.size.y - 1))) / 10)
	inner_lines = []
	player_on_outer_lines = true

func move_if_possible(x : int, y : int) -> void:
	if player_on_outer_lines:
		if is_on_outer_line(x, y):
			player_pos = Vector2i(x, y)
		return
	# Process building new inner line
	if is_on_outer_line(x, y):
		# completed area
		complete_loop(x, y)
		return
	if is_on_inner_line(x, y):
		on_player_death()
		return
	if does_extend_line(x, y, inner_lines.back()[0], inner_lines.back()[1]):
		inner_lines.back()[1] = Vector2i(x, y)
		player_pos = Vector2i(x, y)
		return
	inner_lines.append([player_pos, Vector2i(x, y)])
	player_pos = Vector2i(x, y)

func _process(delta: float) -> void:
	queue_redraw()
	rotate_player += 5.0 * delta
	process_player_input(delta)

func process_player_input(delta : float) -> void:
	if player_on_outer_lines == false:
		# player is burning new path
		process_inner_line_input(delta)
		return
	if process_outer_line_input(delta):
		return
	if Input.is_key_pressed(KEY_SPACE):
		process_inner_path_start()

func start_inner_path(x : int, y : int) -> void:
	assert(inner_lines.is_empty())
	var ix : int = player_pos.x + x
	var iy : int = player_pos.y + y
	if ix < 0 || iy < 0 || ix >= play_field.size.x || iy >= play_field.size.y:
		# Player trying to move outside of playing area
		return

	# Don't let player draw outside remaining area
	var path_el_on_outer_line : Array = get_outer_line_element(player_pos)
	var triangle_of_intent_path : Array = [
		[path_el_on_outer_line[0], player_pos],
		[player_pos, Vector2i(ix, iy)],
		[Vector2i(ix, iy), path_el_on_outer_line[0]]
	]
	if get_signed_area_of_path(triangle_of_intent_path) < 0: # neg is counter clockwise path
		return

	if is_on_outer_line(ix, iy):
		# player trying to jump off one line onto another? Shouldn't happen, but stop it
		print("Shouldn't happen?! Player starting innner line onto outer line")
		return
	player_on_outer_lines = false
	inner_lines.append([player_pos, Vector2i(ix, iy)])
	player_pos = Vector2i(ix, iy)

func process_inner_path_start() -> void:
	if (Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S)):
		start_inner_path(0, 1);
	elif (Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W)):
		start_inner_path(0, -1);
	elif (Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D)):
		start_inner_path(1, 0);
	elif (Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A)):
		start_inner_path(-1, 0);
	# else player is just holding down space but no direction - that's ok.

func process_inner_line_input(delta : float) -> void:
	if (Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S)): # && !is_direction_on_outer_line(0, 1):
		add_player_direction(0, delta)
	elif (Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W)): # && !is_direction_on_outer_line(0, -1):
		add_player_direction(0, -delta)
	elif (Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D)): # && !is_direction_on_outer_line(1, 0):
		add_player_direction(delta, 0)
	elif (Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A)): # && !is_direction_on_outer_line(-1, 0):
		add_player_direction(-delta, 0)
	
func process_outer_line_input(delta : float) -> bool:
	if (Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_S)) && is_direction_on_outer_line(0, 1):
		add_player_direction(0, delta)
		return true
	elif (Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_W)) && is_direction_on_outer_line(0, -1):
		add_player_direction(0, -delta)
		return true
	elif (Input.is_key_pressed(KEY_RIGHT) || Input.is_key_pressed(KEY_D)) && is_direction_on_outer_line(1, 0):
		add_player_direction(delta, 0)
		return true
	elif (Input.is_key_pressed(KEY_LEFT) || Input.is_key_pressed(KEY_A)) && is_direction_on_outer_line(-1, 0):
		add_player_direction(-delta, 0)
		return true
	return false

#func fancy_draw_line(start : Vector2, end : Vector2, color : Color) -> void:
#	var delta : Vector2 = end - start
#	var inc : float = float(1) / 10
#	for j in range(0, 10):
#		var i = float(j)/10
#		var dcolor = lerp(Color.GREEN, color, i)
#		draw_line(start + i * delta, start + (i + inc) * delta, dcolor)

var rotate_player : float = 0
func _draw() -> void:
	if play_field == null:
		return
		
	var offset : Vector2 = play_field.global_position - self.global_position

	for rect : Rect2i in completed_rects:
		draw_rect(Rect2(rect.position as Vector2 + offset, rect.size), Color.YELLOW)

	for line : Array in outer_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.WHITE)
	for line : Array in inner_lines:
		draw_line(offset + (line[0] as Vector2), offset + (line[1] as Vector2), Color.RED)
	
	var player_length : int = 4
	var rp : int = round(rotate_player) as int
	var p_loc : Vector2 = offset + (player_pos as Vector2)
	if rp % 2 == 0:
		self.draw_line(p_loc - Vector2(player_length, 0), p_loc + Vector2(player_length, 0), Color.BLUE)
		self.draw_line(p_loc - Vector2(0, player_length), p_loc + Vector2(0, player_length), Color.BLUE)
	elif rp % 2 == 1:
		self.draw_line(p_loc - Vector2(player_length, player_length), p_loc + Vector2(player_length, player_length), Color.BLUE)
		self.draw_line(p_loc - Vector2(-player_length, player_length), p_loc + Vector2(-player_length, player_length), Color.BLUE)

func add_line(start : Vector2i, end : Vector2i) -> void:
	outer_lines.append([start, end])

func init_game() -> void:
	play_field = find_child("PlayField") as Control
	score_label = find_child("Score") as Label
	outer_lines = []
	inner_lines = []
	completed_rects = []
	score = 0
	player_on_outer_lines = true
	var pfs : Vector2i = Vector2i(int(play_field.size.x) - 1, int(play_field.size.y) - 1) 
	add_line(Vector2i(0,0), Vector2i(pfs.x, 0))
	add_line(Vector2i(pfs.x, 0), pfs)
	add_line(pfs, Vector2i(0, pfs.y))
	add_line(Vector2i(0, pfs.y), Vector2i(0,0))
	play_field.hide() # TODO: Move the drawing code to a script running on the play_field
	player_pos = Vector2(0, play_field.size.y / 2)

func enter_state() -> void:
	super.enter_state()
	if fade_in:
		self.modulate = Color(Color.WHITE, 0)
		var tween : Tween = get_tree().create_tween()
		var destination_color : Color = Color(Color.WHITE, 1)
		tween.tween_property(self, "modulate", destination_color, fade_time)
	call_deferred("init_game")

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

func on_player_death() -> void:
	print("TODO: Implement better death handling")
	leave_state("Menu")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_menu_pressed() -> void:
	leave_state("Menu")
