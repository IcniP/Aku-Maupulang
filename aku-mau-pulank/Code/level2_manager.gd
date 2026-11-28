extends Node2D
# Dipasang di root scene level 2 (Scene/level2.tscn).
# Memilih aksara acak lalu membagikan cerita ke papan, soal ke pintu, dan memasang hitbox pintu ke Level 3.

signal level_selesai

@export var next_scene: PackedScene = preload("res://Scene/level3.tscn")
@export var puzzles: Array[AksaraPuzzle] = [
	preload("res://Puzzles/aksara_jawa.tres"),
	preload("res://Puzzles/aksara_sunda.tres"),
]

var active_puzzle: AksaraPuzzle
var posisi_pintu: Vector2 = Vector2(48, -50)
var _keluar_aktif := false
var _jeda_toast := false

func _ready() -> void:
	active_puzzle = puzzles.pick_random()
	assert(active_puzzle.is_solvable(), "Puzzle %s tidak bisa diselesaikan" % active_puzzle.script_name)
	var papan := get_tree().get_nodes_in_group("papan")
	# cerita yang memuat kata soal didahulukan, supaya tetap lolos bila papan < jumlah cerita
	var rest: Array = active_puzzle.boards.filter(func(b): return not active_puzzle.uses_question(b))
	rest.shuffle()
	var boards: Array = active_puzzle.boards.filter(func(b): return active_puzzle.uses_question(b)) + rest
	if papan.size() < boards.size():
		push_warning("Papan (%d) kurang dari jumlah cerita (%d)" % [papan.size(), boards.size()])
	boards.resize(mini(boards.size(), papan.size()))
	boards.shuffle()
	papan.shuffle()
	for n in papan.size():
		papan[n].puzzle = active_puzzle
		papan[n].board = boards[n] if n < boards.size() else null

	for d in get_tree().get_nodes_in_group("pintu_soal"):
		d.puzzle = active_puzzle
		posisi_pintu = d.get_parent().position
		d.opened.connect(_on_pintu_dibuka.bind(d))

func _on_pintu_dibuka(door_node) -> void:
	if _keluar_aktif:
		return
	_keluar_aktif = true
	posisi_pintu = door_node.get_parent().position
	level_selesai.emit()
	var pemicu := PintuKeluar.buat_pemicu_keluar(posisi_pintu, "LANJUT -> Level 3", _on_masuk_pintu)
	add_child(pemicu)

func _on_masuk_pintu(body: Node2D) -> void:
	if not (body is Player):
		return
	pindah_level()

func pindah_level() -> void:
	if next_scene == null:
		if not _jeda_toast:
			_jeda_toast = true
			InventoryUI.show_message("Level berikutnya belum tersedia")
			get_tree().create_timer(2.5).timeout.connect(func() -> void: _jeda_toast = false)
		return
	get_tree().change_scene_to_packed.call_deferred(next_scene)
