extends CenterContainer

var pos_on_field_A : Vector2
var pos_on_field_B : Vector2
var direction_A : Vector2
var direction_B : Vector2

var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var start_color_hue : float = Color.DARK_VIOLET.h
var end_color_hue : float = Color.AQUAMARINE.h
var color_index : int = 0
var max_shadows : int = 25
var next_shadow_write : float = 0
var shadow_start : Array = []
var shadow_end : Array = []
var change_dir_countdown : float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("init_pos")

func init_pos() -> void:
	pos_on_field_A = random_location()
	pos_on_field_B = random_location()
	direction_A = random_direction()
	direction_B = random_direction()

func random_direction() -> Vector2:
	return Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10)).normalized()

func random_location() -> Vector2:
	return Vector2(rng.randf_range(position.x + 1, position.x + size.x - 1), rng.randf_range(position.y + 1, position.y + size.y - 1))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	queue_redraw()

	change_dir_countdown -= delta
	if change_dir_countdown <= 0:
		change_dir_countdown = 1
		direction_A = random_direction()
		direction_B = random_direction()
	
	pos_on_field_A += direction_A
	if pos_on_field_A.x < position.x || pos_on_field_A.x > (position.x + size.x):
		direction_A.x *= -1
		pos_on_field_A.x += direction_A.x
	if pos_on_field_A.y < position.y || pos_on_field_A.y > (position.y + size.y):
		direction_A.y *= -1
		pos_on_field_A.y += direction_A.y

	pos_on_field_B += direction_B
	if pos_on_field_B.x < position.x || pos_on_field_B.x > (position.x + size.x):
		direction_B.x *= -1
		pos_on_field_B.x += direction_A.x
	if pos_on_field_B.y < position.y || pos_on_field_B.y > (position.y + size.y):
		direction_B.y *= -1
		pos_on_field_B.y += direction_A.y
	
	next_shadow_write -= delta
	if next_shadow_write <= 0:
		next_shadow_write = 2.0 / max_shadows
		if shadow_start.size() < max_shadows:
			shadow_start.append(pos_on_field_A)
			shadow_end.append(pos_on_field_B)
			color_index = shadow_start.size() - 1
		else:
			color_index = (1 + color_index) % shadow_start.size()
			shadow_start[color_index] = pos_on_field_A
			shadow_end[color_index] = pos_on_field_B

func _draw() -> void:
	for i in range(0, shadow_start.size()):
		var n : int = (i + color_index) % shadow_start.size()
		var frac : float = i / float(shadow_start.size() - 1)
		var color : Color = Color.from_hsv(lerp(start_color_hue, end_color_hue, frac), 1, 1)
		draw_line(shadow_start[n], shadow_end[n], color, 0.6)
