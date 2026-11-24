extends Interactable

signal puzzle_solved

const REQUIRED_COUNT := 2

var required: Array[ItemData] = []
var placed: Array[ItemData] = [null, null]
var solved := false

func _ready() -> void:
	add_to_group("meja")
	interact_name = "Periksa meja"

func set_required(items: Array[ItemData]) -> void:
	required = items.duplicate()
	placed.clear()
	for _i in maxi(REQUIRED_COUNT, required.size()):
		placed.append(null)
	solved = false

func interact() -> void:
	InventoryUI.open_backpack(self)
	await InventoryUI.closed

func hint_text() -> String:
	if required.is_empty():
		return "Belum ada petunjuk."
	var region_label := required[0].region_name
	if region_label.is_empty():
		region_label = String(required[0].region).capitalize()
	var lines: Array[String] = [
		"Masukkan %d jenis batik khas %s:" % [required.size(), region_label]
	]
	for i in required.size():
		lines.append("%d. %s" % [i + 1, required[i].hint])
	return "\n".join(lines)

func slot_count() -> int:
	return placed.size()

func placed_count() -> int:
	var n := 0
	for item in placed:
		if item != null:
			n += 1
	return n

func placed_at(slot_index: int) -> ItemData:
	if slot_index < 0 or slot_index >= placed.size():
		return null
	return placed[slot_index]

func can_place_at(slot_index: int) -> bool:
	return not solved and slot_index >= 0 and slot_index < placed.size() and placed[slot_index] == null

func try_place(item: ItemData, slot_index: int = -1) -> bool:
	if solved or item == null:
		return false
	if slot_index < 0:
		slot_index = placed.find(null)
	if not can_place_at(slot_index):
		return false
	placed[slot_index] = item
	if _is_all_correct():
		solved = true
	Inventory.remove(item)
	if solved:
		InventoryUI.show_message("Benar! Kedua batik cocok. Pintu terbuka.")
		puzzle_solved.emit()
	elif placed_count() < required.size():
		if _is_required_item(item):
			InventoryUI.show_message("Batik cocok (%d/%d). Masukkan batik kedua dari daerah yang sama." % [placed_count(), required.size()])
		else:
			InventoryUI.show_message("Sepertinya bukan batik dari daerah ini...")
	else:
		InventoryUI.show_message("Belum tepat! Pastikan kedua batik berasal dari daerah yang diminta.")
	return true

func take_back(slot_index: int = 0) -> bool:
	if solved or slot_index < 0 or slot_index >= placed.size():
		return false
	if placed[slot_index] == null:
		return false
	if Inventory.is_full():
		InventoryUI.show_message("Inventory penuh (maks %d)" % Inventory.MAX_ITEMS)
		return false
	var item := placed[slot_index]
	placed[slot_index] = null
	Inventory.add(item)
	return true

func _is_required_item(item: ItemData) -> bool:
	for req in required:
		if req != null and req.id == item.id:
			return true
	return false

func _is_all_correct() -> bool:
	if required.is_empty() or placed.size() < required.size():
		return false
	var placed_ids := {}
	for item in placed:
		if item == null:
			return false
		placed_ids[item.id] = true
	if placed_ids.size() != required.size():
		return false
	for req in required:
		if req == null or not placed_ids.has(req.id):
			return false
	return true
