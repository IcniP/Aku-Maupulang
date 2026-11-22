extends Node
# Uji penyambungan Level 3 -> Level 4 (change_scene sungguhan). Jalankan:
#   godot --headless --path . res://Tools/level34_link_test.tscn
# Level dijadikan current_scene (bukan node uji ini) supaya node uji tidak ikut dibebaskan saat pindah scene.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("  [ok]   ", pesan)
	else:
		_gagal += 1
		print("  [GAGAL] ", pesan)

func _tunggu(n: int = 3) -> void:
	for _i in n:
		await get_tree().physics_frame
	await get_tree().process_frame

func _ready() -> void:
	_jalankan.call_deferred()   # root masih sibuk saat _ready: tambah child setelahnya

func _jalankan() -> void:
	print("=== Sambungan Level 3 -> Level 4 ===")
	var paket: PackedScene = load("res://Scene/level3.tscn")
	var lvl3: Node = paket.instantiate()
	get_tree().root.add_child(lvl3)
	get_tree().current_scene = lvl3
	await _tunggu(3)
	_cek(lvl3.next_scene != null and lvl3.next_scene.resource_path == "res://Scene/level4.tscn", "Level 3: next_scene terisi Scene/level4.tscn")
	var hasil: Level3Generator.Hasil = lvl3.hasil
	_cek(hasil != null and hasil.valid(), "Level 3 valid; kode jawaban %s" % hasil.kode_teks())
	var panel: PanelKode = lvl3.panel_kode
	_cek(panel.coba_kode(hasil.kode_teks()), "kode benar -> pintu Level 3 terbuka")
	await _tunggu(3)
	var pemain: Player = lvl3.get_node("Y-Sort/Player")
	pemain.global_position = lvl3.posisi_pintu + Vector2(0, -30)
	await _tunggu(2)
	pemain.global_position = lvl3.posisi_pintu
	await _tunggu(8)
	var skrg := get_tree().current_scene
	_cek(skrg != null and skrg.name == "Level4", "melangkah ke pintu Level 3 -> pindah ke Level 4 (scene aktif: %s)" % (skrg.name if skrg else "null"))
	if skrg != null and skrg.name == "Level4":
		_cek(skrg.hasil != null and skrg.hasil.valid() and skrg.get_node_or_null("SejarahUI") != null, "Level 4 hasil pindahan valid dan UI dibuat")
		_cek(skrg.next_scene == null, "Level 4: next_scene tetap kosong (Level 5 belum ada)")
		_cek(not get_tree().paused, "game tidak tertinggal dalam keadaan pause")
	print("\n=== SELESAI: %s ===" % ("SEMUA LULUS" if _gagal == 0 else "%d PEMERIKSAAN GAGAL" % _gagal))
	get_tree().quit(0 if _gagal == 0 else 1)
