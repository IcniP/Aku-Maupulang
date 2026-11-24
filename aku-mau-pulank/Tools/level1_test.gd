extends Node
# Skrip uji Level 1 (2 batik dari 1 daerah, 2 submission di meja).
# Jalankan:
#   godot --headless --path . res://Tools/level1_test.tscn

var _gagal := 0

func _ready() -> void:
	_uji_pool()
	await _uji_randomizer_dan_scene()
	print("\n=== SELESAI: %s ===" % ("SEMUA LULUS" if _gagal == 0 else "%d PEMERIKSAAN GAGAL" % _gagal))
	get_tree().quit(0 if _gagal == 0 else 1)

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("  [ok]   ", pesan)
	else:
		_gagal += 1
		print("  [GAGAL] ", pesan)

func _reset_inventory() -> void:
	for i in Inventory.MAX_ITEMS:
		Inventory.items[i] = null
	Inventory.selected = 0
	Inventory.changed.emit()

func _uji_pool() -> void:
	print("=== 1. Uji Pool Batik per Daerah ===")
	var rand_script := load("res://Code/lemari_randomizer.gd")
	var inst = rand_script.new()
	var pool: Array[ItemData] = inst.pool
	_cek(pool.size() == 6, "Pool berisi 6 batik (%d)" % pool.size())

	var by_region := {}
	var ids := {}
	for item in pool:
		_cek(item != null, "Item tidak null")
		_cek(item.id != &"" and not ids.has(item.id), "ID unik: %s" % item.id)
		ids[item.id] = true
		_cek(not item.display_name.is_empty(), "Display name ada: %s" % item.display_name)
		_cek(item.region != &"" and not item.region_name.is_empty(), "Region terisi: %s (%s)" % [item.region, item.region_name])
		_cek(item.icon != null and item.large_image != null, "Texture icon & large_image ada: %s" % item.id)
		_cek(not item.description.is_empty() and not item.hint.is_empty(), "Description & hint ada: %s" % item.id)
		if not by_region.has(item.region):
			by_region[item.region] = []
		by_region[item.region].append(item)

	_cek(by_region.has(&"lampung") and by_region[&"lampung"].size() == 2, "Lampung punya 2 jenis batik (kapal & gajah)")
	_cek(by_region.has(&"yogyakarta") and by_region[&"yogyakarta"].size() == 2, "Yogyakarta punya 2 jenis batik (parang & kawung)")
	_cek(by_region.has(&"cirebon") and by_region[&"cirebon"].size() == 2, "Cirebon punya 2 jenis batik (mega mendung & singa barong)")
	inst.free()

func _uji_randomizer_dan_scene() -> void:
	print("\n=== 2. Uji Randomizer (15 run) & Alur 2 Submission ===")
	var game_scene: PackedScene = load("res://Scene/game.tscn")
	_cek(game_scene != null, "Scene/game.tscn berhasil dimuat")
	if game_scene == null:
		return

	var seen_regions := {}
	for run in 15:
		var root := game_scene.instantiate()
		add_child(root)
		await get_tree().process_frame

		var mejas := get_tree().get_nodes_in_group("meja")
		var lemaris := get_tree().get_nodes_in_group("lemari")
		if run == 0:
			_cek(mejas.size() == 1, "Ada 1 meja di Level 1 (%d)" % mejas.size())
			_cek(lemaris.size() == 6, "Ada 6 lemari di Level 1 (%d)" % lemaris.size())

		var meja = mejas[0]
		_cek(meja.required.size() == 2, "Run %d: meja membutuhkan 2 batik" % run)
		_cek(meja.required[0].region == meja.required[1].region, "Run %d: kedua batik berasal dari 1 daerah (%s)" % [run, meja.required[0].region])
		_cek(meja.required[0].id != meja.required[1].id, "Run %d: kedua batik berbeda jenis" % run)
		seen_regions[meja.required[0].region] = true

		var lemari_ids := {}
		for l in lemaris:
			if l.item != null:
				lemari_ids[l.item.id] = true
		_cek(lemari_ids.has(meja.required[0].id) and lemari_ids.has(meja.required[1].id), "Run %d: kedua batik target tersedia di lemari" % run)
		_cek(lemari_ids.size() == 6, "Run %d: semua 6 lemari berisi 6 batik unik" % run)

		if run == 0:
			await _uji_gameplay(meja, lemaris)

		root.queue_free()
		await get_tree().process_frame

	_cek(seen_regions.size() >= 2, "Randomizer memilih daerah secara acak (%d daerah terlihat dalam 15 run)" % seen_regions.size())

func _uji_gameplay(meja, lemaris: Array) -> void:
	print("\n=== 3. Uji Interaksi Meja, InventoryUI, & 2 Submission ===")
	_reset_inventory()

	var req0: ItemData = meja.required[0]
	var req1: ItemData = meja.required[1]
	var wrong: ItemData = null
	var lemari_req0 = null
	var lemari_req1 = null
	var lemari_wrong = null
	for l in lemaris:
		if l.item == req0:
			lemari_req0 = l
		elif l.item == req1:
			lemari_req1 = l
		elif wrong == null and l.item != null and l.item.region != req0.region:
			wrong = l.item
			lemari_wrong = l

	_cek(lemari_req0 != null and lemari_req1 != null and lemari_wrong != null, "Menemukan lemari untuk 2 batik benar & 1 batik salah")

	# Ambil 3 item ke inventory
	lemari_wrong.interact()
	lemari_req0.interact()
	lemari_req1.interact()
	_cek(Inventory.items.has(wrong) and Inventory.items.has(req0) and Inventory.items.has(req1), "3 batik masuk ke inventory")

	# Buka UI meja
	InventoryUI.open_backpack(meja)
	_cek(InventoryUI.drop_zones.size() >= 2 and InventoryUI.drop_zones[0].visible and InventoryUI.drop_zones[1].visible, "InventoryUI menampilkan 2 slot drop zone")
	_cek(InventoryUI.hint_label.text.contains(req0.region_name), "Hint menyebut nama daerah (%s)" % req0.region_name)
	_cek(InventoryUI.hint_label.text.contains(req0.hint) and InventoryUI.hint_label.text.contains(req1.hint), "Hint memuat petunjuk kedua motif")
	_cek(InventoryUI.table_status_label.text.contains("0 / 2"), "Status awal menampilkan 0 / 2")

	var solved_count := [0]
	meja.puzzle_solved.connect(func(): solved_count[0] += 1)

	# 1) Taruh batik salah di slot 0 -> belum selesai
	_cek(meja.try_place(wrong, 0), "Menaruh batik salah di slot 0 berhasil")
	_cek(not meja.solved and solved_count[0] == 0, "Belum selesai setelah 1 batik salah")
	_cek(InventoryUI.table_status_label.text.contains("1 / 2"), "Status menampilkan 1 / 2")

	# 2) Taruh 1 batik benar di slot 1 -> total 2 tapi 1 salah -> belum selesai
	_cek(meja.try_place(req1, 1), "Menaruh batik benar #2 di slot 1 berhasil")
	_cek(not meja.solved and solved_count[0] == 0, "Belum selesai bila 1 benar + 1 salah")
	_cek(InventoryUI.toast_label.text.contains("Belum tepat"), "Toast memberi tahu kombinasi belum tepat")

	# 3) Ambil kembali batik salah dari slot 0
	_cek(meja.take_back(0), "Mengambil kembali batik salah dari slot 0 berhasil")
	_cek(meja.placed_at(0) == null and meja.placed_at(1) == req1, "Slot 0 kosong, slot 1 tetap berisi batik benar #2")
	_cek(Inventory.items.has(wrong), "Batik salah kembali ke inventory")

	# 4) Taruh batik benar #1 ke slot 0 (urutan terbalik: slot 0 = req0, slot 1 = req1) -> SELESAI!
	_cek(meja.try_place(req0, 0), "Menaruh batik benar #1 di slot 0 berhasil")
	_cek(meja.solved and solved_count[0] == 1, "Puzzle selesai setelah 2 batik dari daerah sama dimasukkan")
	_cek(InventoryUI.drop_zones[0].disabled and InventoryUI.drop_zones[1].disabled, "Drop zone terkunci setelah selesai")
	_cek(InventoryUI.table_status_label.text.contains("Selesai"), "Status menampilkan pesan selesai")
	_cek(not meja.take_back(0), "Tidak bisa mengambil kembali batik setelah puzzle selesai")

	InventoryUI.close()
	_reset_inventory()
