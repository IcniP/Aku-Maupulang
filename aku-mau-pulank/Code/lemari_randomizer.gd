extends Node2D

signal level_selesai

const REQUIRED_PER_REGION := 2

@export var next_scene: PackedScene = preload("res://Scene/level2.tscn")
@export var posisi_pintu: Vector2 = Vector2(27, -56)
@export var pool: Array[ItemData] = [
	preload("res://Items/batik_lampung.tres"),
	preload("res://Items/batik_lampung_gajah.tres"),
	preload("res://Items/batik_parang.tres"),
	preload("res://Items/batik_kawung.tres"),
	preload("res://Items/batik_mega_mendung.tres"),
	preload("res://Items/batik_cirebon_singa_barong.tres"),
]

var pintu: Node2D
var _keluar_aktif := false
var _jeda_toast := false

@onready var _ysort: Node2D = $"Y-Sort"

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

	pintu = PintuKeluar.buat_pintu_terkunci(posisi_pintu, "PINTU - Level 2")
	_ysort.add_child(pintu)

	for m in get_tree().get_nodes_in_group("meja"):
		m.set_required(required_items)
		m.puzzle_solved.connect(_on_puzzle_solved)

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

func _on_puzzle_solved() -> void:
	if _keluar_aktif:
		return
	_keluar_aktif = true
	if pintu != null:
		pintu.get_node("Pintu/CollisionShape2D").set_deferred("disabled", true)
		pintu.hide()
	level_selesai.emit()
	var pemicu := PintuKeluar.buat_pemicu_keluar(posisi_pintu, "LANJUT -> Level 2", _on_masuk_pintu)
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
	Inventory.clear()
	get_tree().change_scene_to_packed.call_deferred(next_scene)
