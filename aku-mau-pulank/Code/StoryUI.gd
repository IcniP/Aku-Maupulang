extends CanvasLayer
# Autoload "StoryUI": panel papan cerita (aksara + penjelasan) dan panel soal di pintu.

signal closed

var panel: PanelContainer
var title_label: Label
var aksara_label: Label
var explain_box: VBoxContainer
var grid: GridContainer
var translation_label: Label
var door_box: HBoxContainer
var answer_edit: LineEdit
var status_label: Label
var door   # pintu_soal yang sedang dibuka

var _backdrop: ColorRect

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	_backdrop = UITheme.make_backdrop()
	add_child(_backdrop)

	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	UITheme.style_parchment_panel(panel, 26, 22)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.custom_minimum_size.x = 580
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	title_label = UITheme.make_title("", 22, false)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var esc_hint := UITheme.make_body("Esc untuk menutup", 13, true, false)
	esc_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(esc_hint)
	root.add_child(UITheme.make_divider(false))

	var aksara_card := PanelContainer.new()
	UITheme.style_inner_box(aksara_card, 16, false)
	root.add_child(aksara_card)
	aksara_label = _label("", 34)
	aksara_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aksara_card.add_child(aksara_label)

	explain_box = VBoxContainer.new()
	explain_box.add_theme_constant_override("separation", 10)
	root.add_child(explain_box)
	var exp_title := UITheme.make_title("Penjelasan Kata", 16, false)
	explain_box.add_child(exp_title)

	var grid_card := PanelContainer.new()
	UITheme.style_inner_box(grid_card, 12, false)
	explain_box.add_child(grid_card)
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	grid_card.add_child(grid)

	translation_label = UITheme.make_body("", 15, false, false)
	explain_box.add_child(translation_label)

	door_box = HBoxContainer.new()
	door_box.add_theme_constant_override("separation", 10)
	root.add_child(door_box)
	answer_edit = LineEdit.new()
	answer_edit.placeholder_text = "Ketik jawabanmu..."
	answer_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_edit.custom_minimum_size.y = 42
	answer_edit.text_submitted.connect(func(_t): _submit())
	door_box.add_child(answer_edit)
	var send := Button.new()
	send.text = "Jawab"
	send.custom_minimum_size = Vector2(110, 42)
	UITheme.style_button(send, "primary")
	send.pressed.connect(_submit)
	door_box.add_child(send)

	status_label = UITheme.make_body("", 14, true, false)
	root.add_child(status_label)

	var close_btn := Button.new()
	close_btn.text = "Tutup"
	UITheme.style_button(close_btn, "secondary")
	close_btn.pressed.connect(close)
	root.add_child(close_btn)

func _label(text: String, size: int, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.TEXT_DARK)
	if font:
		l.add_theme_font_override("font", font)
	return l

func _set_aksara(text: String, font: Font) -> void:
	aksara_label.text = text
	if font:
		aksara_label.add_theme_font_override("font", font)
	else:
		aksara_label.remove_theme_font_override("font")

func open_board(board: StoryBoard, font: Font) -> void:
	door = null
	title_label.text = board.title
	_set_aksara(" ".join(board.words), font)
	for c in grid.get_children():
		c.queue_free()
	for i in mini(board.words.size(), board.meanings.size()):
		grid.add_child(_label(board.words[i], 26, font))
		grid.add_child(_label("=  " + board.meanings[i], 15))
	translation_label.text = "Arti kalimat: " + board.translation
	explain_box.visible = true
	door_box.visible = false
	status_label.text = ""
	_show()

func open_door(puzzle: AksaraPuzzle, d) -> void:
	door = d
	title_label.text = "Soal di Pintu (%s)" % puzzle.script_name
	_set_aksara(" ".join(puzzle.question_words), puzzle.get_font())
	explain_box.visible = false
	door_box.visible = true
	answer_edit.clear()
	status_label.text = "Cocokkan tiap kata dengan papan cerita, artikan soalnya, lalu jawab."
	status_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_show()
	answer_edit.grab_focus()

func _show() -> void:
	_backdrop.visible = true
	panel.visible = true
	get_tree().paused = true

func close() -> void:
	if not panel.visible:
		return
	_backdrop.visible = false
	panel.visible = false
	door = null
	get_tree().paused = false
	closed.emit()

func _submit() -> void:
	if door == null:
		return
	if door.try_answer(answer_edit.text):
		close()
	else:
		status_label.text = "Jawaban salah. Periksa lagi papan cerita."
		status_label.add_theme_color_override("font_color", UITheme.ACCENT_DANGER)

func _unhandled_input(event: InputEvent) -> void:
	if panel.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
