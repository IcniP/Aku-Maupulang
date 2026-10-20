extends Interactable
# Diisi level2_manager.gd saat game mulai.

var puzzle: AksaraPuzzle
var board: StoryBoard

func _ready() -> void:
	add_to_group("papan")
	interact_name = "Baca papan cerita"

func interact() -> void:
	if board == null:
		return
	StoryUI.open_board(board, puzzle.get_font())
	await StoryUI.closed
