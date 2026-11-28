extends Control
# Main Menu: pilihan Normal, Hard (timer 10 menit), Pengaturan (layar & volume), dan Keluar.

var menu_card: PanelContainer
var settings_panel: SettingsPanel
var btn_normal: Button
var btn_hard: Button
var btn_settings: Button
var btn_quit: Button

func _ready() -> void:
	get_tree().paused = false
	theme = UITheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Latar gelap hangat museum
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.045, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Bingkai dekoratif tipis di sekeliling layar
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 22
	frame.offset_top = 22
	frame.offset_right = -22
	frame.offset_bottom = -22
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UITheme.make_box(Color.TRANSPARENT, Color(0.78, 0.60, 0.30, 0.32), 2, 16, 0, 0))
	add_child(frame)

	# Kartu menu utama
	menu_card = PanelContainer.new()
	menu_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	menu_card.custom_minimum_size = Vector2(460, 0)
	UITheme.style_dark_panel(menu_card, 34, 30)
	add_child(menu_card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	menu_card.add_child(col)

	var badge := UITheme.make_body("MUSEUM NUSANTARA", 12, true, true)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", UITheme.BORDER_GOLD)
	col.add_child(badge)

	var title := UITheme.make_title("AKU MAU PULANG", 34, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var subtitle := UITheme.make_body("Pecahkan teka-teki di 4 ruangan budaya Nusantara untuk membuka jalan pulang.", 14, true, true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(subtitle)

	col.add_child(UITheme.make_divider(true))

	btn_normal = _make_mode_button(
		"Normal",
		"Bermain santai tanpa batas waktu",
		"primary",
		func() -> void: GameManager.start_game(GameManager.Mode.NORMAL)
	)
	col.add_child(btn_normal)

	btn_hard = _make_mode_button(
		"Hard  •  10 Menit",
		"Selesaikan semua level dalam 10 menit atau kalah",
		"danger",
		func() -> void: GameManager.start_game(GameManager.Mode.HARD)
	)
	col.add_child(btn_hard)

	btn_settings = Button.new()
	btn_settings.text = "Pengaturan  (Layar & Volume)"
	btn_settings.custom_minimum_size.y = 44
	UITheme.style_button(btn_settings, "secondary")
	btn_settings.pressed.connect(_open_settings)
	col.add_child(btn_settings)

	col.add_child(UITheme.make_divider(true))

	btn_quit = Button.new()
	btn_quit.text = "Keluar"
	btn_quit.custom_minimum_size.y = 40
	UITheme.style_button(btn_quit, "secondary")
	btn_quit.pressed.connect(func() -> void: get_tree().quit())
	col.add_child(btn_quit)

	var controls_hint := UITheme.make_body("Kontrol: WASD bergerak  •  E interaksi  •  I ransel  •  N catatan  •  Esc jeda", 12, true, true)
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(controls_hint)

	# Panel Pengaturan
	settings_panel = SettingsPanel.new()
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	settings_panel.visible = false
	settings_panel.closed.connect(_close_settings)
	add_child(settings_panel)

func _make_mode_button(label_text: String, desc_text: String, variant: String, action: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 62)
	UITheme.style_button(btn, variant)
	btn.pressed.connect(action)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	btn.add_child(box)

	var main_lbl := Label.new()
	main_lbl.text = label_text
	main_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_lbl.add_theme_font_size_override("font_size", 18)
	main_lbl.add_theme_color_override("font_color", Color.WHITE)
	main_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(main_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = desc_text
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.96, 0.91, 0.84, 0.88))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(sub_lbl)

	return btn

func _open_settings() -> void:
	menu_card.visible = false
	settings_panel.sync_from_manager()
	settings_panel.visible = true

func _close_settings() -> void:
	settings_panel.visible = false
	menu_card.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()
		get_viewport().set_input_as_handled()
