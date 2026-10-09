extends Interactable

signal puzzle_solved

var required: ItemData   
var placed: ItemData
var solved := false

func _ready() -> void:
	add_to_group("meja")
	interact_name = "Periksa meja"

func interact() -> void:
	InventoryUI.open_backpack(self)
	await InventoryUI.closed

func hint_text() -> String:
	return required.hint if required else "Belum ada petunjuk."

func try_place(item: ItemData) -> void:
	if placed or solved:
		return
	placed = item
	Inventory.remove(item)  
	if required and item.id == required.id:
		solved = true
		InventoryUI.show_message("Benar! Pintu terbuka.")
		puzzle_solved.emit()
	else:
		InventoryUI.show_message("Sepertinya bukan ini...")

func take_back() -> void:
	if placed == null:
		return
	if Inventory.is_full():
		InventoryUI.show_message("Inventory penuh (maks %d)" % Inventory.MAX_ITEMS)
		return
	var item := placed
	placed = null
	solved = false
	Inventory.add(item)
