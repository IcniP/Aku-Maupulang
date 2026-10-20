extends Interactable

signal opened

var puzzle: AksaraPuzzle
var is_open := false

func _ready() -> void:
	add_to_group("pintu_soal")
	interact_name = "Periksa pintu"

func interact() -> void:
	if is_open or puzzle == null:
		return
	StoryUI.open_door(puzzle, self)
	await StoryUI.closed

func try_answer(text: String) -> bool:
	if not puzzle.answers.has(text.strip_edges().to_lower()):
		return false
	is_open = true
	is_interactable = false
	get_parent().get_node("Pintu/CollisionShape2D").set_deferred("disabled", true)
	get_parent().hide()
	InventoryUI.show_message("Pintu terbuka!")
	opened.emit()
	return true
