extends Node2D
# Dipasang di root scene level 2. Memilih aksara acak lalu membagikan cerita ke papan dan soal ke pintu.

@export var puzzles: Array[AksaraPuzzle] = [
	preload("res://Puzzles/aksara_jawa.tres"),
	preload("res://Puzzles/aksara_sunda.tres"),
]

func _ready() -> void:
	var puzzle: AksaraPuzzle = puzzles.pick_random()
	assert(puzzle.is_solvable(), "Puzzle %s tidak bisa diselesaikan" % puzzle.script_name)
	var papan := get_tree().get_nodes_in_group("papan")
	# cerita yang memuat kata soal didahulukan, supaya tetap lolos bila papan < jumlah cerita
	var rest: Array = puzzle.boards.filter(func(b): return not puzzle.uses_question(b))
	rest.shuffle()
	var boards: Array = puzzle.boards.filter(func(b): return puzzle.uses_question(b)) + rest
	if papan.size() < boards.size():
		push_warning("Papan (%d) kurang dari jumlah cerita (%d)" % [papan.size(), boards.size()])
	boards.resize(mini(boards.size(), papan.size()))
	boards.shuffle()
	papan.shuffle()
	for n in papan.size():
		papan[n].puzzle = puzzle
		papan[n].board = boards[n] if n < boards.size() else null
	for d in get_tree().get_nodes_in_group("pintu_soal"):
		d.puzzle = puzzle
