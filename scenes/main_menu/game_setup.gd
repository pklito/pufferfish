extends Control

signal started(s: Game.GameSettings)

enum RowStatus { VACANT, CENTER, LEFT, RIGHT }

var _game_settings: Game.GameSettings = Game.GameSettings.new()
var _input_ids: Array
var _rows_status: Array[RowStatus]

@export var _sides_grid: GridContainer
@export var _start_button: Button

const NUM_ROWS := 6
const JOYPAD_TEXTURE = preload("res://assets/ui/controller_generic.svg")
const KEYBOARD_TEXTURE = preload("res://assets/ui/keyboard.svg")

const LEFT_COLOR = Color.BLUE
const RIGHT_COLOR = Color.RED
const OFF_COLOR = Color(0.25, 0.25, 0.25)

func _ready() -> void:
	# connect signals
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

	# init arrays and grid
	_input_ids.resize(NUM_ROWS)
	_rows_status.resize(NUM_ROWS)
	for i in range(NUM_ROWS): _set_vacant(i)
	_update_vacant_display()
	_update_start_button()

func _on_start_pressed() -> void:
	# TODO: maybe check if everything is valid again just in case
	
	# get players settings for game settings
	var players_settings: Array[Pufferfish.PlayerSettings] = []
	for i in range(NUM_ROWS):
		if _rows_status[i] == RowStatus.VACANT: continue
		var p_setting := Pufferfish.PlayerSettings.new()
		p_setting.input_id = _input_ids[i]
		p_setting.name = _get_name(i)
		p_setting.team = Game.Team.LEFT if _rows_status[i] == RowStatus.LEFT else Game.Team.RIGHT
		players_settings.append(p_setting)
	_game_settings.players_settings = players_settings

	started.emit(_game_settings)

func _get_grid_panel(row: int, col: int) -> PanelContainer:
	return _sides_grid.get_child(3*row + col)

func _input(event: InputEvent) -> void:
	# if a joypad just pressed any button
	if event is InputEventJoypadButton and event.is_pressed() and not event.is_echo():
		# if the joypad was not pressed before
		if not event.device in _input_ids: _player_join(event.device)
		# joypad is already registered
		else:
			if event.is_action("ui_left"): _on_input_left(event.device)
			elif event.is_action("ui_right"): _on_input_right(event.device)
			elif event.is_action("ui_back"): _on_input_back(event.device)
			#elif event.is_action("ui_ok"): pass
	# if the action is from a keyboard
	elif event is InputEventKey:
		if "k1" not in _input_ids and event.is_action_pressed("k1_explode"):
			_player_join("k1")
		if "k2" not in _input_ids and event.is_action_pressed("k2_explode"):
			_player_join("k2")
		if "k1" in _input_ids:
			if event.is_action_pressed("k1_turn_left"): _on_input_left("k1")
			elif event.is_action_pressed("k1_turn_right"): _on_input_right("k1")
			elif event.is_action_pressed("k1_shrink"): _on_input_back("k1")
		if "k2" in _input_ids:
			if event.is_action_pressed("k2_turn_left"): _on_input_left("k2")
			elif event.is_action_pressed("k2_turn_right"): _on_input_right("k2")
			elif event.is_action_pressed("k2_shrink"): _on_input_back("k2")

## returns first vacant row, or -1 if none are vacant
func _next_available_slot() -> int:
	for i in range(NUM_ROWS): if _rows_status[i] == RowStatus.VACANT: return i
	return -1

## returns row of device
func _dev_to_row(device) -> int:
	for i in range(NUM_ROWS):
		if typeof(_input_ids[i]) == typeof(device) and _input_ids[i] == device: return i
	return -1

## reset row r to be vacant
func _set_vacant(r: int) -> void:
	_input_ids[r] = null
	_rows_status[r] = RowStatus.VACANT
	_set_center_on(false, r)
	_set_left_on(false, r)
	_set_right_on(false, r)

func _update_start_button() -> void:
	var l = 0; var r = 0
	for i in range(NUM_ROWS):
		if _rows_status[i] == RowStatus.CENTER:
			_start_button.disabled = true
			return
		elif _rows_status[i] == RowStatus.LEFT: l += 1
		elif _rows_status[i] == RowStatus.RIGHT: r += 1
	if l > 0 and r > 0: _start_button.disabled = false
	else: _start_button.disabled = true

## updates first vacant row to the press to join prompt
func _update_vacant_display() -> void:
	var r = _next_available_slot()
	if r == -1: return
	# show vacant prompt at first vacant row
	_get_grid_panel(r,1).find_child("Label").visible = true
	# hide all future vacant prompts
	r += 1
	while r < NUM_ROWS:
		if _rows_status[r] == RowStatus.VACANT: _get_grid_panel(r,1).find_child("Label").visible = false
		r += 1

## return the name of the player in the given row
func _get_name(row: int) -> String:
	var line_edit: LineEdit = _sides_grid.get_child(3*row + 1).get_child(0).get_child(1)
	return line_edit.text if line_edit.text != "" else line_edit.placeholder_text

## called when unregistered player does an input
func _player_join(device) -> void:
	var vacant_row = _next_available_slot()
	if vacant_row == -1: return

	# set row status and save device id
	_input_ids[vacant_row] = device
	_rows_status[vacant_row] = RowStatus.CENTER

	# TODO: detect joypad and set specific controller textures
	var controller_texture = KEYBOARD_TEXTURE if device is String else JOYPAD_TEXTURE

	# set controller textures
	_get_grid_panel(vacant_row, 0).find_child("Controller").texture = controller_texture
	_get_grid_panel(vacant_row, 1).find_child("Controller").texture = controller_texture
	_get_grid_panel(vacant_row, 2).find_child("Controller").texture = controller_texture

	_set_center_on(true, vacant_row)

	_update_vacant_display()

## called when player leaves
func _player_leave(device) -> void:
	# find index of player device
	var dev_row: int = _dev_to_row(device)
	if dev_row == -1: return
	# reset row
	_set_vacant(dev_row)

	_update_vacant_display()
	_update_start_button()

func _set_center_on(on: bool, row: int) -> void:
	var center: PanelContainer = _get_grid_panel(row, 1)
	center.find_child("LeftArrow").visible = on
	center.find_child("RightArrow").visible = on
	center.find_child("Controller").visible = on
	var line_edit = center.find_child("LineEdit")
	line_edit.editable = on
	line_edit.visible = on
	center.find_child("Label").visible = false

func _set_left_on(on: bool, row: int) -> void:
	var left: PanelContainer = _get_grid_panel(row, 0)
	# update panel style
	var style: StyleBoxFlat = left.get_theme_stylebox("panel").duplicate()
	style.bg_color = LEFT_COLOR if on else OFF_COLOR
	left.add_theme_stylebox_override("panel", style)
	# update name label
	if on: left.find_child("Label").text = _get_name(row)
	# show icons
	left.get_child(0).visible = on

func _set_right_on(on: bool, row: int) -> void:
	var right: PanelContainer = _get_grid_panel(row, 2)
	# update panel style
	var style: StyleBoxFlat = right.get_theme_stylebox("panel").duplicate()
	style.bg_color = RIGHT_COLOR if on else OFF_COLOR
	right.add_theme_stylebox_override("panel", style)
	# update name label
	if on: right.find_child("Label").text = _get_name(row)
	# show icons
	right.get_child(0).visible = on

func _on_input_left(device) -> void:
	var row = _dev_to_row(device)
	match _rows_status[row]:
		RowStatus.CENTER:
			_set_center_on(false, row)
			_rows_status[row] = RowStatus.LEFT
			_set_left_on(true, row)
			_update_start_button()
		RowStatus.RIGHT:
			_set_right_on(false, row)
			_rows_status[row] = RowStatus.CENTER
			_set_center_on(true, row)
			_update_start_button()

func _on_input_right(device) -> void:
	var row = _dev_to_row(device)
	match _rows_status[row]:
		RowStatus.CENTER:
			_set_center_on(false, row)
			_rows_status[row] = RowStatus.RIGHT
			_set_right_on(true, row)
			_update_start_button()
		RowStatus.LEFT:
			_set_left_on(false, row)
			_rows_status[row] = RowStatus.CENTER
			_set_center_on(true, row)
			_update_start_button()

func _on_input_back(device) -> void:
	_player_leave(device)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and device in _input_ids: _player_leave(device)
