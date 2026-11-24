extends Node2D

const REQUIRED_PER_REGION := 2

@export var pool: Array[ItemData] = [
	preload("res://Items/batik_lampung.tres"),
	preload("res://Items/batik_lampung_gajah.tres"),
	preload("res://Items/batik_parang.tres"),
	preload("res://Items/batik_kawung.tres"),
	preload("res://Items/batik_mega_mendung.tres"),
	preload("res://Items/batik_cirebon_singa_barong.tres"),
]

func _ready() -> void:
	var by_region := {}
	for item in pool:
		if item == null or item.region == &"":
			continue
		if not by_region.has(item.region):
			by_region[item.region] = []
		by_region[item.region].append(item)

	var valid_regions: Array = []
	for region_id in by_region:
		if by_region[region_id].size() >= REQUIRED_PER_REGION:
			valid_regions.append(region_id)
	assert(not valid_regions.is_empty(), "Tidak ada daerah dengan minimal %d batik di pool." % REQUIRED_PER_REGION)

	var chosen_region: StringName = valid_regions.pick_random()
	var region_items: Array = by_region[chosen_region].duplicate()
	region_items.shuffle()
	var required_items: Array[ItemData] = []
	for i in REQUIRED_PER_REGION:
		required_items.append(region_items[i])

	for m in get_tree().get_nodes_in_group("meja"):
		m.set_required(required_items)

	var boxes := get_tree().get_nodes_in_group("lemari")
	if boxes.size() < required_items.size():
		push_warning("Jumlah lemari (%d) kurang dari batik yang diminta (%d)" % [boxes.size(), required_items.size()])

	var decoys: Array = pool.filter(func(i): return i != null and not required_items.has(i))
	decoys.shuffle()
	var items: Array = []
	items.append_array(required_items)
	items.append_array(decoys)
	items.resize(mini(items.size(), boxes.size()))
	items.shuffle()
	boxes.shuffle()
	for n in boxes.size():
		boxes[n].set_item(items[n] if n < items.size() else null)
