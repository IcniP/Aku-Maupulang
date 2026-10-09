extends Node
# Autoload "Inventory": data inventory pemain.

signal changed

const MAX_ITEMS := 3

# slot tetap: item tidak bergeser, slot kosong = null
var items: Array[ItemData] = [null, null, null]
var selected := 0

func is_full() -> bool:
	return not items.has(null)

func add(item: ItemData) -> bool:
	if item == null or is_full():
		return false
	items[items.find(null)] = item
	changed.emit()
	return true

func remove(item: ItemData) -> void:
	var i := items.find(item)
	if i >= 0:
		items[i] = null
	changed.emit()

func select(index: int) -> void:
	selected = clampi(index, 0, MAX_ITEMS - 1)
	changed.emit()

func selected_item() -> ItemData:
	return items[selected]
