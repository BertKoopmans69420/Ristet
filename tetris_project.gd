extends Node2D

const GRID_WIDTH = 10
const GRID_HEIGHT = 20
const CELL_SIZE = 30
const SPAWN_X = 4
const SPAWN_Y = 0

# Game states
enum GameState { START_SCREEN, PLAYING, PAUSED }
var game_state = GameState.START_SCREEN
var selected_theme = 0

# Theme definitions
var themes = [
	{
		"name": "Game Boy",
		"dark": Color("#0f380f"),
		"dark_gray": Color("#1a4d1a"),
		"light_gray": Color("#8bac0f"),
		"light": Color("#9bbc0f"),
		"background": Color("#306230"),
		"bezel": Color("#2d5a2d"),
		"screen_border": Color("#1a3a1a")
	},
	{
		"name": "Purple",
		"dark": Color("#2a0845"),
		"dark_gray": Color("#4a1a8a"),
		"light_gray": Color("#9a6aff"),
		"light": Color("#bb88ff"),
		"background": Color("#3a1a5a"),
		"bezel": Color("#5a3a7a"),
		"screen_border": Color("#1a0a3a")
	},
	{
		"name": "Ocean",
		"dark": Color("#001f3f"),
		"dark_gray": Color("#003366"),
		"light_gray": Color("#00ff99"),
		"light": Color("#00ffff"),
		"background": Color("#0a2a4a"),
		"bezel": Color("#1a4a6a"),
		"screen_border": Color("#001a3f")
	},
	{
		"name": "Fire",
		"dark": Color("#330000"),
		"dark_gray": Color("#660000"),
		"light_gray": Color("#ff9900"),
		"light": Color("#ffff00"),
		"background": Color("#4a1a0a"),
		"bezel": Color("#8a3a1a"),
		"screen_border": Color("#220000")
	},
	{
		"name": "Classic",
		"dark": Color("#333333"),
		"dark_gray": Color("#555555"),
		"light_gray": Color("#bbbbbb"),
		"light": Color("#ffffff"),
		"background": Color("#444444"),
		"bezel": Color("#666666"),
		"screen_border": Color("#222222")
	},
	{
		"name": "Retro",
		"dark": Color("#1a1a1a"),
		"dark_gray": Color("#2d2d2d"),
		"light_gray": Color("#ffaa00"),
		"light": Color("#ffdd55"),
		"background": Color("#3a3a1a"),
		"bezel": Color("#5a5a2a"),
		"screen_border": Color("#0a0a0a")
	}
]

# Active theme colors
var theme_dark = Color("#0f380f")
var theme_dark_gray = Color("#1a4d1a")
var theme_light_gray = Color("#8bac0f")
var theme_light = Color("#9bbc0f")
var theme_background = Color("#306230")
var theme_bezel = Color("#2d5a2d")
var theme_screen_border = Color("#1a3a1a")

var retro_font: Font

var grid = []
var current_piece = null
var next_piece = null
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
	"I": theme_light,
	"O": theme_light,
	"T": theme_light,
	"S": theme_light,
	"Z": theme_light,
	"J": theme_light,
	"L": theme_light
}

var last_a_pressed = false
var last_d_pressed = false

func _ready():
	retro_font = load("res://retro_computer_personal_use.ttf")
	load_theme(selected_theme)
	init_grid()
	spawn_piece()
	calculate_offset()

func load_theme(theme_idx):
	var theme = themes[theme_idx]
	theme_dark = theme["dark"]
	theme_dark_gray = theme["dark_gray"]
	theme_light_gray = theme["light_gray"]
	theme_light = theme["light"]
	theme_background = theme["background"]
	theme_bezel = theme["bezel"]
	theme_screen_border = theme["screen_border"]
	
	# Update tetromino colors
	for key in tetromino_colors.keys():
		tetromino_colors[key] = theme_light
	
	queue_redraw()

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
	
	if next_piece == null:
		next_piece = {
			"type": types[randi() % types.size()],
			"shape": tetromino_shapes[types[randi() % types.size()]],
			"rotation": 0
		}
	
	current_piece = next_piece
	var new_type = types[randi() % types.size()]
	next_piece = {
		"type": new_type,
		"shape": tetromino_shapes[new_type],
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
	if game_state == GameState.START_SCREEN:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_A:
				selected_theme = (selected_theme - 1) % themes.size()
				queue_redraw()
			elif event.keycode == KEY_D:
				selected_theme = (selected_theme + 1) % themes.size()
				queue_redraw()
			elif event.keycode == KEY_S or event.keycode == KEY_SPACE:
				game_state = GameState.PLAYING
				load_theme(selected_theme)
				queue_redraw()
	elif game_state == GameState.PLAYING:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				game_state = GameState.PAUSED
				queue_redraw()
			elif event.keycode == KEY_LEFT:
				rotate_piece_left()
				queue_redraw()
			elif event.keycode == KEY_RIGHT:
				rotate_piece_right()
				queue_redraw()
	elif game_state == GameState.PAUSED:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				game_state = GameState.PLAYING
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
	if game_state != GameState.PLAYING:
		return
	
	# Handle movement input - single press only
	var a_pressed = Input.is_key_pressed(KEY_A)
	var d_pressed = Input.is_key_pressed(KEY_D)
	
	# Move left only on key transition (not pressed -> pressed)
	if a_pressed and not last_a_pressed:
		if can_place_piece(current_x - 1, current_y, current_piece["shape"]):
			current_x -= 1
			queue_redraw()
	
	# Move right only on key transition (not pressed -> pressed)
	if d_pressed and not last_d_pressed:
		if can_place_piece(current_x + 1, current_y, current_piece["shape"]):
			current_x += 1
			queue_redraw()
	
	last_a_pressed = a_pressed
	last_d_pressed = d_pressed
	
	# Gravity and S (down) input
	fall_timer += delta
	var down_pressed = Input.is_key_pressed(KEY_S)
	var current_fall_speed = fall_speed if not down_pressed else fall_speed * 0.1
	
	if fall_timer >= current_fall_speed:
		fall_timer = 0.0
		
		if can_place_piece(current_x, current_y + 1, current_piece["shape"]):
			current_y += 1
		else:
			place_piece()
		
		queue_redraw()

func _draw():
	if game_state == GameState.START_SCREEN:
		draw_start_screen()
	else:
		draw_gameboy_device()
		draw_grid_background()
		draw_grid_lines()
		draw_placed_blocks()
		draw_current_piece()
		draw_scoreboard()
		draw_next_preview()
		
		if game_state == GameState.PAUSED:
			draw_pause_menu()

func draw_start_screen():
	var viewport_size = get_viewport_rect().size
	var bezel_color = Color("#8B8B83")
	var dark_bezel = Color("#5A5A52")
	
	draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), bezel_color)
	
	# Draw outer shadow/border for 3D effect
	for i in range(8):
		draw_rect(Rect2(i, i, viewport_size.x - i * 2, viewport_size.y - i * 2), dark_bezel, false, 1.0)
	
	# Draw title
	var title_y = 80
	draw_string(retro_font, Vector2(160, title_y), "SELECT THEME", 0, -1, 24, Color.BLACK)
	
	# Draw themes
	var themes_per_row = 2
	var theme_box_width = 120
	var theme_box_height = 100
	var start_x = 100
	var start_y = 200
	var spacing_x = 180
	var spacing_y = 140
	
	for i in range(themes.size()):
		var row = i / themes_per_row
		var col = i % themes_per_row
		var x = start_x + col * spacing_x
		var y = start_y + row * spacing_y
		
		var is_selected = (i == selected_theme)
		var box_color = themes[i]["light"]
		var border_color = Color.WHITE if is_selected else Color.BLACK
		var border_thickness = 4.0 if is_selected else 2.0
		
		# Draw theme box
		draw_rect(Rect2(x, y, theme_box_width, theme_box_height), themes[i]["background"])
		draw_rect(Rect2(x, y, theme_box_width, theme_box_height), border_color, false, border_thickness)
		
		# Draw theme name
		draw_string(retro_font, Vector2(x + 10, y + 40), themes[i]["name"], 0, -1, 14, box_color)
		
		# Draw selection indicator
		if is_selected:
			draw_string(retro_font, Vector2(x + 20, y + 65), "> SELECT <", 0, -1, 10, box_color)

func draw_gameboy_device():
	# Draw outer bezel/device body
	var viewport_size = get_viewport_rect().size
	var bezel_color = Color("#8B8B83")
	var dark_bezel = Color("#5A5A52")
	
	draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), bezel_color)
	
	# Draw outer shadow/border for 3D effect
	for i in range(8):
		draw_rect(Rect2(i, i, viewport_size.x - i * 2, viewport_size.y - i * 2), dark_bezel, false, 1.0)
	
	# Draw screen area frame around the actual game grid
	var screen_frame_x = offset_x - 12
	var screen_frame_y = offset_y - 12
	var screen_frame_w = GRID_WIDTH * CELL_SIZE + 24
	var screen_frame_h = GRID_HEIGHT * CELL_SIZE + 24
	
	draw_rect(Rect2(screen_frame_x, screen_frame_y, screen_frame_w, screen_frame_h), theme_screen_border)
	draw_rect(Rect2(screen_frame_x + 8, screen_frame_y + 8, screen_frame_w - 16, screen_frame_h - 16), Color.BLACK, false, 2.0)
	
	# Draw speaker grilles above screen
	var speaker_y = screen_frame_y + screen_frame_h + 30
	var speaker_spacing = 8
	for x in range(screen_frame_x + 20, screen_frame_x + screen_frame_w - 20, speaker_spacing):
		draw_line(Vector2(x, speaker_y), Vector2(x, speaker_y + 30), Color("#3A3A32"), 1.0)
	
	# Draw D-Pad area
	var dpad_x = screen_frame_x + 30
	var dpad_y = speaker_y + 60
	draw_rect(Rect2(dpad_x - 5, dpad_y - 5, 60, 60), Color("#6A6A62"))
	# D-pad shape (cross)
	draw_rect(Rect2(dpad_x + 15, dpad_y, 30, 60), Color("#4A4A42"))
	draw_rect(Rect2(dpad_x, dpad_y + 15, 60, 30), Color("#4A4A42"))
	
	# Draw buttons area on right
	var button_x = screen_frame_x + screen_frame_w - 80
	var button_y = dpad_y
	# A button (red)
	draw_circle(Vector2(button_x + 40, button_y + 40), 15, Color("#C84C3C"))
	draw_circle(Vector2(button_x + 40, button_y + 40), 15, Color("#A83020"), false, 2.0)
	# B button (red)
	draw_circle(Vector2(button_x, button_y), 15, Color("#C84C3C"))
	draw_circle(Vector2(button_x, button_y), 15, Color("#A83020"), false, 2.0)
	
	# Draw Start/Select area
	var select_y = dpad_y + 80
	draw_rect(Rect2(screen_frame_x + 60, select_y, 100, 20), Color("#6A6A62"))
	draw_rect(Rect2(screen_frame_x + 180, select_y, 100, 20), Color("#6A6A62"))

func draw_grid_background():
	draw_rect(Rect2(offset_x, offset_y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), theme_dark_gray)

func draw_grid_lines():
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(offset_x + x * CELL_SIZE, offset_y), Vector2(offset_x + x * CELL_SIZE, offset_y + GRID_HEIGHT * CELL_SIZE), theme_dark)
	
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(offset_x, offset_y + y * CELL_SIZE), Vector2(offset_x + GRID_WIDTH * CELL_SIZE, offset_y + y * CELL_SIZE), theme_dark)

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
	var scoreboard_y = offset_y
	var box_width = 140
	var box_height = 160
	
	# Draw retro Game Boy style box
	draw_rect(Rect2(scoreboard_x - 10, scoreboard_y - 10, box_width, box_height), theme_dark_gray)
	draw_rect(Rect2(scoreboard_x - 10, scoreboard_y - 10, box_width, box_height), theme_light, false, 2.0)
	
	# Draw score value
	draw_string(retro_font, Vector2(scoreboard_x, scoreboard_y + 25), "SCORE", 0, -1, 12, theme_light)
	draw_string(retro_font, Vector2(scoreboard_x, scoreboard_y + 50), str(score), 0, -1, 18, theme_light)
	
	# Draw lines cleared
	draw_string(retro_font, Vector2(scoreboard_x, scoreboard_y + 105), "LINES", 0, -1, 12, theme_light_gray)
	draw_string(retro_font, Vector2(scoreboard_x, scoreboard_y + 130), str(lines_cleared), 0, -1, 18, theme_light)

func draw_next_preview():
	var preview_x = offset_x + GRID_WIDTH * CELL_SIZE + 30
	var preview_y = offset_y + 200
	var box_width = 140
	var box_height = 140
	
	# Draw preview box
	draw_rect(Rect2(preview_x - 10, preview_y - 10, box_width, box_height), theme_dark_gray)
	draw_rect(Rect2(preview_x - 10, preview_y - 10, box_width, box_height), theme_light, false, 2.0)
	
	# Draw title
	draw_string(retro_font, Vector2(preview_x, preview_y + 60), "NEXT", 0, -1, 14, theme_light)
	
	# Draw next piece preview
	if next_piece != null:
		var shape = next_piece["shape"]
		var piece_color = tetromino_colors[next_piece["type"]]
		
		var preview_start_x = preview_x + 15
		var preview_start_y = preview_y + 10
		var cell_size = 12
		
		for row_idx in range(shape.size()):
			for col_idx in range(shape[row_idx].size()):
				if shape[row_idx][col_idx] == 1:
					var x = preview_start_x + col_idx * cell_size
					var y = preview_start_y + row_idx * cell_size
					draw_rect(Rect2(x, y, cell_size, cell_size), piece_color)
					draw_rect(Rect2(x, y, cell_size, cell_size), Color.WHITE, false, 0.5)

func draw_pause_menu():
	var viewport_size = get_viewport_rect().size
	
	# Draw semi-transparent overlay
	draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), Color(0, 0, 0, 0.7))
	
	# Draw pause menu box
	var menu_width = 250
	var menu_height = 200
	var menu_x = (viewport_size.x - menu_width) / 2
	var menu_y = (viewport_size.y - menu_height) / 2
	
	draw_rect(Rect2(menu_x, menu_y, menu_width, menu_height), theme_dark_gray)
	draw_rect(Rect2(menu_x, menu_y, menu_width, menu_height), theme_light, false, 3.0)
	
	# Draw title
	draw_string(retro_font, Vector2(menu_x + 50, menu_y + 30), "PAUSED", 0, -1, 24, theme_light)
	
	# Draw instructions
	draw_string(retro_font, Vector2(menu_x + 25, menu_y + 90), "Press ESC", 0, -1, 16, theme_light_gray)
	draw_string(retro_font, Vector2(menu_x + 20, menu_y + 120), "to continue", 0, -1, 16, theme_light_gray)
