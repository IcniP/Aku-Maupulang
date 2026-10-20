class_name AksaraPuzzle
extends Resource

@export var script_name: String
@export_file("*.ttf", "*.otf", "*.woff2") var font_path: String
@export var boards: Array                # isi: StoryBoard
@export var question_words: PackedStringArray  # soal di pintu, dalam aksara
@export var answers: PackedStringArray   # jawaban benar, huruf kecil

func get_font() -> Font:
	return load(font_path) if font_path != "" and ResourceLoader.exists(font_path) else null

func uses_question(board: StoryBoard) -> bool:
	for w in question_words:
		if board.words.has(w):
			return true
	return false

# Tiap kata soal harus punya arti di salah satu papan, dan jawaban harus ada.
func is_solvable() -> bool:
	if answers.is_empty():
		return false
	for w in question_words:
		if not boards.any(func(b): return b.words.has(w)):
			return false
	return true
