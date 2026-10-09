extends Node2D

@export var pool: Array[ItemData] = [
	preload("res://Items/batik_lampung.tres"),
	preload("res://Items/batik_parang.tres"),
	preload("res://Items/batik_mega_mendung.tres"),
	preload("res://Items/batik_kawung.tres"),
]

func _ready() -> void:
	var correct: ItemData = pool.pick_random()
	for m in get_tree().get_nodes_in_group("meja"):
		m.required = correct
	var boxes := get_tree().get_nodes_in_group("lemari")
	var items: Array = pool.filter(func(i): return i != correct)
	items.shuffle()
	items = [correct] + items
	items.resize(mini(items.size(), boxes.size()))
	items.shuffle()
	boxes.shuffle()
	for n in boxes.size():
		boxes[n].set_item(items[n] if n < items.size() else null)  
