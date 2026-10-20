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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size.x = 560
	panel.add_child(root)
	title_label = _label("", 22)
	root.add_child(title_label)
	aksara_label = _label("", 36)
	root.add_child(aksara_label)

	explain_box = VBoxContainer.new()
	root.add_child(explain_box)
	explain_box.add_child(_label("Penjelasan", 18))
	grid = GridContainer.new()
	grid.columns = 2
	explain_box.add_child(grid)
	translation_label = _label("", 16)
	explain_box.add_child(translation_label)

	door_box = HBoxContainer.new()
	root.add_child(door_box)
	answer_edit = LineEdit.new()
	answer_edit.placeholder_text = "Ketik jawabanmu..."
	answer_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_edit.text_submitted.connect(func(_t): _submit())
	door_box.add_child(answer_edit)
	var send := Button.new()
	send.text = "Jawab"
	send.pressed.connect(_submit)
	door_box.add_child(send)

	status_label = _label("", 16)
	root.add_child(status_label)
	var close_btn := Button.new()
	close_btn.text = "Tutup"
	close_btn.pressed.connect(close)
	root.add_child(close_btn)

func _label(text: String, size: int, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
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
		grid.add_child(_label(board.words[i], 28, font))
		grid.add_child(_label("   = " + board.meanings[i], 16))
	translation_label.text = "Arti kalimat: " + board.translation
	explain_box.visible = true
	door_box.visible = false
	status_label.text = ""
	_show()

func open_door(puzzle: AksaraPuzzle, d) -> void:
	door = d
	title_label.text = "Soal di pintu (%s)" % puzzle.script_name
	_set_aksara(" ".join(puzzle.question_words), puzzle.get_font())
	explain_box.visible = false
	door_box.visible = true
	answer_edit.clear()
	status_label.text = "Cocokkan tiap kata dengan papan cerita, artikan soalnya, lalu jawab."
	_show()
	answer_edit.grab_focus()

func _show() -> void:
	panel.visible = true
	get_tree().paused = true

func close() -> void:
	if not panel.visible:
		return
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

func _unhandled_input(event: InputEvent) -> void:
	if panel.visible and event.is_action_pressed("ui_cancel"):
		close()
