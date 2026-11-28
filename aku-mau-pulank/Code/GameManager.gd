extends CanvasLayer
# Autoload "GameManager": mode Normal/Hard (timer 10 menit), pengaturan layar & volume,
# HUD level/timer, menu jeda (Esc), layar Kalah (waktu habis), dan layar Menang.

enum Mode { NORMAL, HARD }

const HARD_TIME_LIMIT := 600.0  # 10 menit
const SETTINGS_PATH := "user://settings.cfg"
const MAIN_MENU_SCENE := "res://Scene/main_menu.tscn"
const LEVEL_1_SCENE := "res://Scene/game.tscn"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

const LEVEL_LABELS := {
	"Game": "Level 1  •  Galeri Batik",
	"Level2": "Level 2  •  Ruang Aksara",
	"Level3": "Level 3  •  Ruang Pameran",
	"Level4": "Level 4  •  Ruang Sejarah",
}

var mode: Mode = Mode.NORMAL
var is_run_active := false
var time_remaining: float = HARD_TIME_LIMIT
var elapsed_time: float = 0.0
var is_game_over := false
var is_victory := false
var is_paused_menu := false

# Pengaturan
var resolution_index: int = 1  # default 1280x720
var fullscreen: bool = false
var master_volume: float = 0.8

var _last_scene: Node
var _in_gameplay := false

# HUD
var _hud_root: Control
var _level_label: Label
var _mode_label: Label
var _timer_panel: PanelContainer
var _timer_label: Label

# Overlays (Pause / Settings / Game Over / Victory)
var _backdrop: ColorRect
var _pause_panel: PanelContainer
var _pause_info_label: Label
var _settings_panel: SettingsPanel
var _end_panel: PanelContainer
var _end_title: Label
var _end_subtitle: Label
var _end_stats: Label
var _end_retry_btn: Button

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_settings()
	_build_hud()
	_build_overlays()
	if get_tree().has_signal("scene_changed"):
		get_tree().connect("scene_changed", func() -> void: _sync_scene(get_tree().current_scene))
	get_tree().root.child_entered_tree.connect(func(_n: Node) -> void: _sync_scene.call_deferred(get_tree().current_scene))
	_sync_scene(get_tree().current_scene)

func _process(delta: float) -> void:
	var cs := get_tree().current_scene
	if cs != _last_scene:
		_sync_scene(cs)

	if _in_gameplay and is_run_active and not get_tree().paused and not is_game_over and not is_victory:
		elapsed_time += delta
		if mode == Mode.HARD:
			time_remaining = maxf(0.0, time_remaining - delta)
			_update_timer_ui()
			if time_remaining <= 0.0:
				trigger_game_over()

# ---------------------------------------------------------------- Alur permainan

func start_game(selected_mode: Mode) -> void:
	mode = selected_mode
	is_run_active = true
	time_remaining = HARD_TIME_LIMIT
	elapsed_time = 0.0
	is_game_over = false
	is_victory = false
	_hide_all_overlays()
	Inventory.clear()
	get_tree().paused = false
	_update_timer_ui()
	get_tree().change_scene_to_file(LEVEL_1_SCENE)

func return_to_main_menu() -> void:
	is_run_active = false
	is_game_over = false
	is_victory = false
	_hide_all_overlays()
	Inventory.clear()
	InventoryUI.close()
	StoryUI.close()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func complete_game() -> void:
	if is_victory or is_game_over:
		return
	is_victory = true
	is_run_active = false
	_hide_all_overlays()
	_end_title.text = "Selamat! Kamu Berhasil Pulang!"
	_end_title.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	_end_subtitle.text = "Semua 4 ruangan museum telah berhasil kamu pecahkan."
	var mode_text := "Hard (10 Menit)" if mode == Mode.HARD else "Normal"
	var stats := "Mode: %s\nWaktu tempuh: %s" % [mode_text, format_time(elapsed_time)]
	if mode == Mode.HARD:
		stats += "\nSisa waktu: %s" % format_time(time_remaining)
	_end_stats.text = stats
	_end_retry_btn.text = "Main Lagi"
	_backdrop.visible = true
	_end_panel.visible = true
	get_tree().paused = true

func trigger_game_over() -> void:
	if is_game_over or is_victory:
		return
	is_game_over = true
	is_run_active = false
	_hide_all_overlays()
	InventoryUI.close()
	StoryUI.close()
	_close_level_uis()
	_end_title.text = "Waktu Habis!"
	_end_title.add_theme_color_override("font_color", UITheme.TEXT_DANGER)
	_end_subtitle.text = "Kamu tidak berhasil menyelesaikan seluruh ruangan dalam 10 menit."
	_end_stats.text = "Mode: Hard (10 Menit)\nTerhenti di: %s" % _level_label.text
	_end_retry_btn.text = "Coba Lagi (Hard)"
	_backdrop.visible = true
	_end_panel.visible = true
	get_tree().paused = true

# ---------------------------------------------------------------- Pause (Esc)

func open_pause() -> void:
	if not _in_gameplay or is_game_over or is_victory:
		return
	is_paused_menu = true
	_pause_info_label.text = "%s  •  Mode %s" % [
		_level_label.text,
		"Hard (%s)" % format_time(time_remaining) if (is_run_active and mode == Mode.HARD) else "Normal"
	]
	_backdrop.visible = true
	_pause_panel.visible = true
	_settings_panel.visible = false
	get_tree().paused = true

func close_pause() -> void:
	if not is_paused_menu:
		return
	is_paused_menu = false
	_backdrop.visible = false
	_pause_panel.visible = false
	_settings_panel.visible = false
	get_tree().paused = false

func _open_pause_settings() -> void:
	_pause_panel.visible = false
	_settings_panel.sync_from_manager()
	_settings_panel.visible = true

func _close_pause_settings() -> void:
	_settings_panel.visible = false
	_pause_panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings_panel.visible and is_paused_menu:
		_close_pause_settings()
		get_viewport().set_input_as_handled()
		return
	if is_paused_menu:
		close_pause()
		get_viewport().set_input_as_handled()
		return
	if not _in_gameplay or is_game_over or is_victory:
		return
	if _is_other_ui_open() or get_tree().paused:
		return
	open_pause()
	get_viewport().set_input_as_handled()

func _is_other_ui_open() -> bool:
	if InventoryUI.panel != null and InventoryUI.panel.visible:
		return true
	if StoryUI.panel != null and StoryUI.panel.visible:
		return true
	for n in get_tree().get_nodes_in_group("level3_ui"):
		if n.has_method("sedang_terbuka") and n.sedang_terbuka():
			return true
	for n in get_tree().get_nodes_in_group("sejarah_ui"):
		if n.has_method("sedang_terbuka") and n.sedang_terbuka():
			return true
	return false

func _close_level_uis() -> void:
	for n in get_tree().get_nodes_in_group("level3_ui"):
		if n.has_method("tutup"):
			n.tutup()
	for n in get_tree().get_nodes_in_group("sejarah_ui"):
		if n.has_method("tutup"):
			n.tutup()

# ---------------------------------------------------------------- Pengaturan Layar & Volume

func set_resolution(idx: int) -> void:
	resolution_index = clampi(idx, 0, RESOLUTIONS.size() - 1)
	apply_settings()
	save_settings()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_settings()
	save_settings()

func set_volume(linear_value: float) -> void:
	master_volume = clampf(linear_value, 0.0, 1.0)
	_apply_audio()
	save_settings()

func apply_settings() -> void:
	_apply_audio()
	_apply_display()

func _apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	if master_volume <= 0.001:
		AudioServer.set_bus_mute(bus, true)
		AudioServer.set_bus_volume_db(bus, -80.0)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume))

func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var target: Vector2i = RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]
		DisplayServer.window_set_size(target)
		var screen := DisplayServer.window_get_current_screen()
		var usable := DisplayServer.screen_get_usable_rect(screen)
		var pos := usable.position + (usable.size - target) / 2
		DisplayServer.window_set_position(pos)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "resolution_index", resolution_index)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	resolution_index = clampi(int(cfg.get_value("display", "resolution_index", 1)), 0, RESOLUTIONS.size() - 1)
	fullscreen = bool(cfg.get_value("display", "fullscreen", false))
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", 0.8)), 0.0, 1.0)

static func format_time(seconds: float) -> String:
	var total := ceili(maxf(0.0, seconds))
	var mins := total / 60
	var secs := total % 60
	return "%02d:%02d" % [mins, secs]

# ---------------------------------------------------------------- Sinkronisasi scene & UI

func _sync_scene(scene: Node) -> void:
	_last_scene = scene
	var scene_name: String = String(scene.name) if scene != null else ""
	_in_gameplay = LEVEL_LABELS.has(scene_name)
	_hud_root.visible = _in_gameplay
	if _in_gameplay:
		_level_label.text = LEVEL_LABELS[scene_name]
		_mode_label.text = "[Esc] Jeda"
		_timer_panel.visible = is_run_active and mode == Mode.HARD
		_update_timer_ui()
		InventoryUI.set_hotbar_visible(scene_name == "Game")
	else:
		InventoryUI.set_hotbar_visible(false)

func _update_timer_ui() -> void:
	if _timer_label == null:
		return
	_timer_label.text = "WAKTU  %s" % format_time(time_remaining)
	if time_remaining <= 60.0:
		_timer_label.add_theme_color_override("font_color", UITheme.TEXT_DANGER)
		UITheme.style_hud_pill(_timer_panel, UITheme.TEXT_DANGER)
	elif time_remaining <= 120.0:
		_timer_label.add_theme_color_override("font_color", UITheme.TEXT_WARN)
		UITheme.style_hud_pill(_timer_panel, UITheme.TEXT_WARN)
	else:
		_timer_label.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
		UITheme.style_hud_pill(_timer_panel, UITheme.BORDER_GOLD)

func _hide_all_overlays() -> void:
	is_paused_menu = false
	_backdrop.visible = false
	_pause_panel.visible = false
	_settings_panel.visible = false
	_end_panel.visible = false

# ---------------------------------------------------------------- Pembangun UI

func _build_hud() -> void:
	_hud_root = Control.new()
	_hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.visible = false
	add_child(_hud_root)

	# Kiri atas: info level + tombol Esc
	var left_pill := PanelContainer.new()
	UITheme.style_hud_pill(left_pill)
	left_pill.position = Vector2(16, 16)
	left_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(left_pill)

	var left_row := HBoxContainer.new()
	left_row.add_theme_constant_override("separation", 14)
	left_pill.add_child(left_row)

	_level_label = UITheme.make_title("Level 1", 15, true)
	left_row.add_child(_level_label)

	_mode_label = UITheme.make_body("[Esc] Jeda", 13, true, true)
	left_row.add_child(_mode_label)

	# Kanan atas: Timer Mode Hard
	_timer_panel = PanelContainer.new()
	UITheme.style_hud_pill(_timer_panel)
	_timer_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_timer_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_timer_panel.offset_right = -16
	_timer_panel.offset_top = 16
	_timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_panel.visible = false
	_hud_root.add_child(_timer_panel)

	_timer_label = UITheme.make_title("WAKTU  10:00", 18, true)
	_timer_panel.add_child(_timer_label)

func _build_overlays() -> void:
	_backdrop = UITheme.make_backdrop()
	add_child(_backdrop)

	# --- Panel Pause ---
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause_panel.custom_minimum_size = Vector2(360, 0)
	_pause_panel.visible = false
	UITheme.style_dark_panel(_pause_panel, 28, 24)
	add_child(_pause_panel)

	var p_col := VBoxContainer.new()
	p_col.add_theme_constant_override("separation", 12)
	_pause_panel.add_child(p_col)

	var p_title := UITheme.make_title("Permainan Dijeda", 24, true)
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_col.add_child(p_title)

	_pause_info_label = UITheme.make_body("", 13, true, true)
	_pause_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_col.add_child(_pause_info_label)
	p_col.add_child(UITheme.make_divider(true))

	var btn_resume := Button.new()
	btn_resume.text = "Lanjutkan"
	UITheme.style_button(btn_resume, "primary")
	btn_resume.pressed.connect(close_pause)
	p_col.add_child(btn_resume)

	var btn_restart := Button.new()
	btn_restart.text = "Ulangi dari Level 1"
	UITheme.style_button(btn_restart, "secondary")
	btn_restart.pressed.connect(func() -> void: start_game(mode))
	p_col.add_child(btn_restart)

	var btn_settings := Button.new()
	btn_settings.text = "Pengaturan"
	UITheme.style_button(btn_settings, "secondary")
	btn_settings.pressed.connect(_open_pause_settings)
	p_col.add_child(btn_settings)

	var btn_menu := Button.new()
	btn_menu.text = "Kembali ke Menu Utama"
	UITheme.style_button(btn_menu, "danger")
	btn_menu.pressed.connect(return_to_main_menu)
	p_col.add_child(btn_menu)

	# --- Panel Settings (dalam Pause) ---
	_settings_panel = SettingsPanel.new()
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_settings_panel.visible = false
	_settings_panel.closed.connect(_close_pause_settings)
	add_child(_settings_panel)

	# --- Panel End (Victory / Game Over) ---
	_end_panel = PanelContainer.new()
	_end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_panel.custom_minimum_size = Vector2(440, 0)
	_end_panel.visible = false
	UITheme.style_dark_panel(_end_panel, 30, 26)
	add_child(_end_panel)

	var e_col := VBoxContainer.new()
	e_col.add_theme_constant_override("separation", 14)
	_end_panel.add_child(e_col)

	_end_title = UITheme.make_title("", 26, true)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_col.add_child(_end_title)

	_end_subtitle = UITheme.make_body("", 15, false, true)
	_end_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_col.add_child(_end_subtitle)

	var stats_box := PanelContainer.new()
	UITheme.style_inner_box(stats_box, 14, true)
	e_col.add_child(stats_box)
	_end_stats = UITheme.make_body("", 15, false, true)
	_end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_child(_end_stats)

	var e_btns := HBoxContainer.new()
	e_btns.add_theme_constant_override("separation", 12)
	e_col.add_child(e_btns)

	_end_retry_btn = Button.new()
	_end_retry_btn.text = "Main Lagi"
	_end_retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_button(_end_retry_btn, "primary")
	_end_retry_btn.pressed.connect(func() -> void: start_game(mode))
	e_btns.add_child(_end_retry_btn)

	var e_menu_btn := Button.new()
	e_menu_btn.text = "Menu Utama"
	e_menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_button(e_menu_btn, "secondary")
	e_menu_btn.pressed.connect(return_to_main_menu)
	e_btns.add_child(e_menu_btn)
