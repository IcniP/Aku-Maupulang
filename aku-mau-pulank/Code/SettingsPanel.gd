class_name SettingsPanel
extends PanelContainer
# Panel pengaturan bersama (dipakai di Main Menu dan Pause Menu):
# ukuran layar, mode layar penuh, dan volume audio.

signal closed

var resolution_option: OptionButton
var fullscreen_check: CheckButton
var volume_slider: HSlider
var volume_value_label: Label
var back_button: Button

func _ready() -> void:
	UITheme.style_dark_panel(self, 28, 24)
	custom_minimum_size = Vector2(460, 0)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var title := UITheme.make_title("Pengaturan", 24, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var sub := UITheme.make_body("Atur ukuran tampilan layar dan volume suara permainan.", 13, true, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)
	root.add_child(UITheme.make_divider(true))

	# Ukuran layar
	var res_box := VBoxContainer.new()
	res_box.add_theme_constant_override("separation", 6)
	root.add_child(res_box)
	res_box.add_child(UITheme.make_body("Ukuran Layar (Windowed)", 15, false, true))
	resolution_option = OptionButton.new()
	resolution_option.focus_mode = Control.FOCUS_NONE
	resolution_option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for i in GameManager.RESOLUTIONS.size():
		var r: Vector2i = GameManager.RESOLUTIONS[i]
		var label := "%d × %d" % [r.x, r.y]
		if r == Vector2i(1280, 720):
			label += "  (HD)"
		elif r == Vector2i(1920, 1080):
			label += "  (Full HD)"
		resolution_option.add_item(label, i)
	resolution_option.item_selected.connect(_on_resolution_selected)
	res_box.add_child(resolution_option)

	# Fullscreen
	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 12)
	root.add_child(fs_row)
	var fs_label := UITheme.make_body("Mode Layar Penuh (Fullscreen)", 15, false, true)
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_row.add_child(fs_label)
	fullscreen_check = CheckButton.new()
	fullscreen_check.focus_mode = Control.FOCUS_NONE
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fs_row.add_child(fullscreen_check)

	root.add_child(UITheme.make_divider(true))

	# Volume slider
	var vol_box := VBoxContainer.new()
	vol_box.add_theme_constant_override("separation", 6)
	root.add_child(vol_box)
	var vol_header := HBoxContainer.new()
	vol_box.add_child(vol_header)
	var vol_lbl := UITheme.make_body("Volume Audio", 15, false, true)
	vol_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_header.add_child(vol_lbl)
	volume_value_label = UITheme.make_title("80%", 15, true)
	vol_header.add_child(volume_value_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.focus_mode = Control.FOCUS_NONE
	volume_slider.value_changed.connect(_on_volume_changed)
	vol_box.add_child(volume_slider)

	root.add_child(UITheme.make_divider(true))

	back_button = Button.new()
	back_button.text = "Kembali"
	UITheme.style_button(back_button, "primary")
	back_button.pressed.connect(func() -> void: closed.emit())
	root.add_child(back_button)

	sync_from_manager()

func sync_from_manager() -> void:
	resolution_option.select(clampi(GameManager.resolution_index, 0, GameManager.RESOLUTIONS.size() - 1))
	fullscreen_check.set_pressed_no_signal(GameManager.fullscreen)
	resolution_option.disabled = GameManager.fullscreen
	var pct := roundi(GameManager.master_volume * 100.0)
	volume_slider.set_value_no_signal(pct)
	volume_value_label.text = "%d%%" % pct

func _on_resolution_selected(idx: int) -> void:
	GameManager.set_resolution(idx)
	sync_from_manager()

func _on_fullscreen_toggled(enabled: bool) -> void:
	GameManager.set_fullscreen(enabled)
	sync_from_manager()

func _on_volume_changed(val: float) -> void:
	GameManager.set_volume(val / 100.0)
	volume_value_label.text = "%d%%" % roundi(val)
