extends Node2D

const GRID_WIDTH = 10
const GRID_HEIGHT = 20
const CELL_SIZE = 30
const SPAWN_X = 4
const SPAWN_Y = 0

var grid = []
var current_piece = null
var current_x = SPAWN_X
var current_y = SPAWN_Y
var fall_timer = 0.0
var fall_speed = 1.0
var score = 0
var lines_cleared = 0
var offset_x = 0
var offset_y = 0

var tetromino_shapes = {
	"I": [[1, 1, 1, 1]],
	"O": [[1, 1], [1, 1]],
	"T": [[0, 1, 0], [1, 1, 1]],
	"S": [[0, 1, 1], [1, 1, 0]],
	"Z": [[1, 1, 0], [0, 1, 1]],
	"J": [[1, 0, 0], [1, 1, 1]],
	"L": [[0, 0, 1], [1, 1, 1]]
}

var tetromino_colors = {
	"I": Color.CYAN,
	"O": Color.YELLOW,
	"T": Color.MAGENTA,
	"S": Color.GREEN,
	"Z": Color.RED,
	"J": Color.BLUE,
	"L": Color.ORANGE
}

func _ready():
	init_grid()
	spawn_piece()
	calculate_offset()

func init_grid():
	grid = []
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append("")
		grid.append(row)

func calculate_offset():
	var viewport_size = get_viewport_rect().size
	var game_width = GRID_WIDTH * CELL_SIZE
	var scoreboard_width = 150
	var total_width = game_width + scoreboard_width
	offset_x = (viewport_size.x - total_width) / 2
	offset_y = (viewport_size.y - GRID_HEIGHT * CELL_SIZE) / 2

func spawn_piece():
	var types = tetromino_shapes.keys()
	var piece_type = types[randi() % types.size()]
	current_piece = {
		"type": piece_type,
		"shape": tetromino_shapes[piece_type],
		"rotation": 0
	}
	current_x = SPAWN_X
	current_y = SPAWN_Y
	
	if not can_place_piece(current_x, current_y, current_piece["shape"]):
		print("Game Over!")
		init_grid()
		spawn_piece()

func can_place_piece(x, y, shape):
	for row_idx in range(shape.size()):
		for col_idx in range(shape[row_idx].size()):
			if shape[row_idx][col_idx] == 1:
				var grid_x = x + col_idx
				var grid_y = y + row_idx
				
				# Check boundaries
				if grid_x < 0 or grid_x >= GRID_WIDTH:
					return false
				if grid_y >= GRID_HEIGHT:
					return false
				
				# Check collision with existing blocks
				if grid_y >= 0 and grid[grid_y][grid_x] != "":
					return false
	
	return true

func place_piece():
	for row_idx in range(current_piece["shape"].size()):
		for col_idx in range(current_piece["shape"][row_idx].size()):
			if current_piece["shape"][row_idx][col_idx] == 1:
				var grid_x = current_x + col_idx
				var grid_y = current_y + row_idx
				
				if grid_y >= 0 and grid_y < GRID_HEIGHT:
					grid[grid_y][grid_x] = current_piece["type"]
	
	clear_lines()
	spawn_piece()
	queue_redraw()

func clear_lines():
	var lines_to_clear = []
	
	for y in range(GRID_HEIGHT):
		var full = true
		for x in range(GRID_WIDTH):
			if grid[y][x] == "":
				full = false
				break
		
		if full:
			lines_to_clear.append(y)
	
	for y in lines_to_clear:
		grid.remove_at(y)
		grid.insert(0, ["", "", "", "", "", "", "", "", "", ""])
	
	if lines_to_clear.size() > 0:
		lines_cleared += lines_to_clear.size()
		score += lines_to_clear.size() * 100

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_A:
			rotate_piece_left()
			queue_redraw()
		elif event.keycode == KEY_D:
			rotate_piece_right()
			queue_redraw()

func rotate_piece():
	var rotated = rotate_shape(current_piece["shape"])
	if can_place_piece(current_x, current_y, rotated):
		current_piece["shape"] = rotated

func rotate_piece_left():
	var rotated = rotate_shape_counterclockwise(current_piece["shape"])
	if can_place_piece(current_x, current_y, rotated):
		current_piece["shape"] = rotated
	else:
		# Try wall kick - adjust position to allow rotation
		if can_place_piece(current_x - 1, current_y, rotated):
			current_x -= 1
			current_piece["shape"] = rotated
		elif can_place_piece(current_x + 1, current_y, rotated):
			current_x += 1
			current_piece["shape"] = rotated

func rotate_piece_right():
	var rotated = rotate_shape(current_piece["shape"])
	if can_place_piece(current_x, current_y, rotated):
		current_piece["shape"] = rotated
	else:
		# Try wall kick - adjust position to allow rotation
		if can_place_piece(current_x - 1, current_y, rotated):
			current_x -= 1
			current_piece["shape"] = rotated
		elif can_place_piece(current_x + 1, current_y, rotated):
			current_x += 1
			current_piece["shape"] = rotated

func rotate_shape_counterclockwise(shape):
	var rows = shape.size()
	var cols = shape[0].size()
	var rotated = []
	
	for x in range(cols - 1, -1, -1):
		var row = []
		for y in range(rows):
			row.append(shape[y][x])
		rotated.append(row)
	
	return rotated

func rotate_shape(shape):
	var rows = shape.size()
	var cols = shape[0].size()
	var rotated = []
	
	for x in range(cols):
		var row = []
		for y in range(rows - 1, -1, -1):
			row.append(shape[y][x])
		rotated.append(row)
	
	return rotated

func _process(delta):
	# Handle movement input - single press per keypress
	if Input.is_action_just_pressed("ui_left"):
		if can_place_piece(current_x - 1, current_y, current_piece["shape"]):
			current_x -= 1
			queue_redraw()
	
	if Input.is_action_just_pressed("ui_right"):
		if can_place_piece(current_x + 1, current_y, current_piece["shape"]):
			current_x += 1
			queue_redraw()
	
	# Gravity and down input
	fall_timer += delta
	var down_pressed = Input.is_action_pressed("ui_down")
	var current_fall_speed = fall_speed if not down_pressed else fall_speed * 0.1
	
	if fall_timer >= current_fall_speed:
		fall_timer = 0.0
		
		if can_place_piece(current_x, current_y + 1, current_piece["shape"]):
			current_y += 1
		else:
			place_piece()
		
		queue_redraw()

func _draw():
	draw_grid_background()
	draw_grid_lines()
	draw_placed_blocks()
	draw_current_piece()
	draw_scoreboard()

func draw_grid_background():
	draw_rect(Rect2(offset_x, offset_y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), Color.BLACK)

func draw_grid_lines():
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(offset_x + x * CELL_SIZE, offset_y), Vector2(offset_x + x * CELL_SIZE, offset_y + GRID_HEIGHT * CELL_SIZE), Color.DARK_GRAY)
	
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(offset_x, offset_y + y * CELL_SIZE), Vector2(offset_x + GRID_WIDTH * CELL_SIZE, offset_y + y * CELL_SIZE), Color.DARK_GRAY)

func draw_placed_blocks():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] != "":
				var color = tetromino_colors[grid[y][x]]
				draw_rect(Rect2(offset_x + x * CELL_SIZE, offset_y + y * CELL_SIZE, CELL_SIZE, CELL_SIZE), color)

func draw_current_piece():
	var color = tetromino_colors[current_piece["type"]]
	
	for row_idx in range(current_piece["shape"].size()):
		for col_idx in range(current_piece["shape"][row_idx].size()):
			if current_piece["shape"][row_idx][col_idx] == 1:
				var x = offset_x + (current_x + col_idx) * CELL_SIZE
				var y = offset_y + (current_y + row_idx) * CELL_SIZE
				draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), color)
				draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), Color.WHITE, false, 1.0)

func draw_scoreboard():
	var scoreboard_x = offset_x + GRID_WIDTH * CELL_SIZE + 30
	var scoreboard_y = offset_y + 20
	var box_width = 140
	var box_height = 180
	
	# Draw background box
	draw_rect(Rect2(scoreboard_x - 10, scoreboard_y - 10, box_width, box_height), Color(0.2, 0.2, 0.2, 0.8))
	draw_rect(Rect2(scoreboard_x - 10, scoreboard_y - 10, box_width, box_height), Color.WHITE, false, 2.0)
	
	# Draw title
	draw_string(ThemeDB.fallback_font, Vector2(scoreboard_x, scoreboard_y), "SCORE", 0, -1, 18, Color.YELLOW)
	
	# Draw score value
	draw_string(ThemeDB.fallback_font, Vector2(scoreboard_x, scoreboard_y + 35), str(score), 0, -1, 20, Color.WHITE)
	
	# Draw lines cleared
	draw_string(ThemeDB.fallback_font, Vector2(scoreboard_x, scoreboard_y + 75), "LINES", 0, -1, 16, Color.CYAN)
	draw_string(ThemeDB.fallback_font, Vector2(scoreboard_x, scoreboard_y + 100), str(lines_cleared), 0, -1, 18, Color.WHITE)
