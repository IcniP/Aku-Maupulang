extends Node
# Skrip uji Level 3. Dijalankan sebagai scene (supaya autoload Inventory/InventoryUI/StoryUI ada).
# Dari folder projek (setelah projek pernah dibuka/di-import):
#   godot --headless --path . res://Tools/level3_test.tscn
# Bagian A: generator untuk 100 seed (allow_zero true & false).
# Bagian B: simulasi permainan di Scene/level3.tscn (interaksi E, UI, panel kode, pintu).

var _gagal := 0

func _ready() -> void:
	var pool := _muat_pool()
	print("=== Pool: %d karya ===" % pool.size())
	_uji_pool(pool)
	_uji_generator(pool, true)
	_uji_generator(pool, false)
	await _uji_scene()
	print("\n=== SELESAI: %s ===" % ("SEMUA LULUS" if _gagal == 0 else "%d PEMERIKSAAN GAGAL" % _gagal))
	get_tree().quit(0 if _gagal == 0 else 1)

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("  [ok]   ", pesan)
	else:
		_gagal += 1
		print("  [GAGAL] ", pesan)

func _muat_pool() -> Array[ExhibitData]:
	var out: Array[ExhibitData] = []
	var dir := DirAccess.open("res://Exhibits")
	var nama_unik := {}
	for f in dir.get_files():
		var nama := f.trim_suffix(".remap")
		if nama.ends_with(".tres"):
			nama_unik[nama] = true
	var urut: Array = nama_unik.keys()
	urut.sort()
	for nama in urut:
		var res := load("res://Exhibits/" + nama)
		if res is ExhibitData:
			out.append(res)
	return out

# ------------------------------------------------------------------ Bagian 0: isi pool

func _uji_pool(pool: Array[ExhibitData]) -> void:
	print("\n=== 0. Isi pool Exhibits/ ===")
	var n_patung := 0
	var n_lukisan := 0
	var id_unik := {}
	var kata_ok := true
	var warna_ok := true
	var min_layak := 999
	var kata_re := RegEx.new()
	kata_re.compile("[A-Za-z]+(?:-[A-Za-z]+)*")
	for e in pool:
		if e.tipe == ExhibitData.Tipe.PATUNG:
			n_patung += 1
		else:
			n_lukisan += 1
		id_unik[e.id] = true
		var jumlah_kata := e.deskripsi.split(" ", false).size()
		var layak := 0
		for m: RegExMatch in kata_re.search_all(e.deskripsi):
			if m.get_string().replace("-", "").length() >= Level3Data.MIN_PANJANG_KATA:
				layak += 1
		min_layak = mini(min_layak, layak)
		if jumlah_kata < 40 or jumlah_kata > 60:
			kata_ok = false
		if layak < Level3Data.MAKS_PER_WARNA + 1 or e.deskripsi.contains("[") or e.judul == "" or e.daerah == "":
			warna_ok = false
		print("  %-34s %-7s %2d kata, %2d kata layak warna" % [e.judul, "patung" if e.tipe == ExhibitData.Tipe.PATUNG else "lukisan", jumlah_kata, layak])
	_cek(n_patung == 10 and n_lukisan == 7, "pool lengkap: %d patung + %d lukisan" % [n_patung, n_lukisan])
	_cek(id_unik.size() == pool.size(), "id semua karya unik")
	_cek(kata_ok, "semua deskripsi 40-60 kata")
	_cek(warna_ok, "tiap label punya >= %d kata (>= 3 huruf) untuk diwarnai, tanpa '[' dan field terisi (min %d)" % [Level3Data.MAKS_PER_WARNA + 1, min_layak])

# ------------------------------------------------------------------ Bagian A

func _uji_generator(pool: Array[ExhibitData], allow_zero: bool) -> void:
	print("\n=== A. Generator, 100 seed, allow_zero=%s ===" % allow_zero)
	var gagal_seed: Array[int] = []
	var butuh_ulang: Array[int] = []
	var kode_unik := {}
	var min_hitung := 99
	var maks_hitung := -1
	var ada_nol := 0
	var tipe_kertas := [0, 0, 0]
	for s in range(1, 101):
		var konf := Level3Generator.konfigurasi_standar(pool, allow_zero, s)
		var h := Level3Generator.buat(konf)
		var hitung := ""
		for w in Level3Data.nama_warna():
			hitung += " %s=%d" % [w.substr(0, 3), h.jumlah_warna.get(w, -1)]
			min_hitung = mini(min_hitung, int(h.jumlah_warna.get(w, 99)))
			maks_hitung = maxi(maks_hitung, int(h.jumlah_warna.get(w, -1)))
		# validasi ulang di luar generator, dari data akhir
		var galat := Level3Generator.validasi(konf, h)
		var ok := h.valid() and galat.is_empty()
		print("seed %3d | kode %s |%s | percobaan %d | %s" % [s, h.kode_teks(), hitung, h.percobaan, "LOLOS" if ok else "GAGAL " + ", ".join(h.galat)])
		if not ok:
			gagal_seed.append(s)
		if h.percobaan > 1:
			butuh_ulang.append(s)
		kode_unik[h.kode_teks()] = true
		if h.kode.has(0):
			ada_nol += 1
		for kr in h.kertas:
			tipe_kertas[kr.tipe] += 1
	print("--- ringkasan ---")
	print("seed gagal setelah %d percobaan: %s" % [Level3Data.MAKS_PERCOBAAN, str(gagal_seed) if not gagal_seed.is_empty() else "tidak ada"])
	print("seed yang butuh acak ulang: %s" % (str(butuh_ulang) if not butuh_ulang.is_empty() else "tidak ada"))
	print("kode berbeda: %d dari 100 | seed dengan angka 0 pada kode: %d" % [kode_unik.size(), ada_nol])
	print("jumlah per warna: min %d, maks %d" % [min_hitung, maks_hitung])
	print("tipe kertas (pojok/lantai/terselip): %s" % str(tipe_kertas))
	_cek(gagal_seed.is_empty(), "100 seed lolos validasi (allow_zero=%s)" % allow_zero)
	_cek(maks_hitung <= Level3Data.MAKS_PER_WARNA, "tidak ada warna > %d" % Level3Data.MAKS_PER_WARNA)
	_cek(min_hitung >= (0 if allow_zero else 1), "batas bawah warna sesuai allow_zero")

	# seed yang sama harus menghasilkan permainan yang sama
	var a := Level3Generator.buat(Level3Generator.konfigurasi_standar(pool, allow_zero, 42))
	var b := Level3Generator.buat(Level3Generator.konfigurasi_standar(pool, allow_zero, 42))
	_cek(a.kode == b.kode and a.karya[0].bbcode == b.karya[0].bbcode, "seed sama -> hasil sama")

# ------------------------------------------------------------------ Bagian B

func _tunggu(n: int = 2) -> void:
	for _i in n:
		await get_tree().physics_frame
	await get_tree().process_frame

func _tekan(aksi: String) -> void:
	var ev := InputEventAction.new()
	ev.action = aksi
	ev.pressed = true
	Input.parse_input_event(ev)
	await _tunggu()

func _uji_scene() -> void:
	print("\n=== B. Simulasi permainan di Scene/level3.tscn ===")
	var lvl: Node = load("res://Scene/level3.tscn").instantiate()
	add_child(lvl)
	await _tunggu(3)
	var hasil: Level3Generator.Hasil = lvl.hasil
	var ui: Level3UI = lvl.ui
	var pemain: Player = lvl.get_node("Y-Sort/Player")
	var interacting: Node = pemain.get_node("interacting")
	_cek(hasil != null and hasil.valid(), "level3.tscn memuat dan hasil generator valid")
	_cek(ui != null, "Level3UI dibuat lewat kode")
	print("  kode jawaban permainan ini: %s" % hasil.kode_teks())

	var karya_nodes := get_tree().get_nodes_in_group("karya_pameran")
	var kertas_nodes := get_tree().get_nodes_in_group("kertas_petunjuk")
	var panel_nodes := get_tree().get_nodes_in_group("panel_kode")
	var n_terselip := 0
	for k in hasil.kertas:
		if k.tipe == Level3Generator.TipeKertas.TERSELIP:
			n_terselip += 1
	_cek(karya_nodes.size() == 7, "7 karya muncul (4 patung + 3 lukisan)")
	_cek(kertas_nodes.size() == Level3Data.CODE_LENGTH - n_terselip, "kertas pojok/lantai muncul sebagai objek (%d)" % kertas_nodes.size())
	_cek(panel_nodes.size() == 1, "1 panel kode")

	var layer_ok := true
	for n in karya_nodes + kertas_nodes + panel_nodes:
		if n.collision_layer != 2 or n.collision_mask != 0:
			layer_ok = false
	_cek(layer_ok, "semua Interactable di collision layer 2")

	# patung punya StaticBody2D, lukisan tidak
	var badan_ok := true
	for n in karya_nodes:
		var punya := false
		for c in n.get_children():
			if c is StaticBody2D:
				punya = true
		if (n.data.tipe == ExhibitData.Tipe.PATUNG) != punya:
			badan_ok = false
	_cek(badan_ok, "patung punya StaticBody2D, lukisan tidak")

	# patung benar-benar menghalangi (query fisika)
	var ruang := pemain.get_world_2d().direct_space_state
	var patung_menghalangi := true
	for n in karya_nodes:
		if n.data.tipe == ExhibitData.Tipe.PATUNG:
			var q := PhysicsPointQueryParameters2D.new()
			q.position = n.global_position + Vector2(0, -3)
			q.collide_with_bodies = true
			if ruang.intersect_point(q).is_empty():
				patung_menghalangi = false
	_cek(patung_menghalangi, "titik di dasar patung terdeteksi sebagai benda padat")

	# tombol N tidak bentrok dengan aksi lain
	var bentrok := false
	for aksi in InputMap.get_actions():
		if aksi == "catatan":
			continue
		for ev in InputMap.action_get_events(aksi):
			if ev is InputEventKey and ev.physical_keycode == KEY_N:
				bentrok = true
	_cek(InputMap.has_action("catatan") and not bentrok, "aksi 'catatan' (N) terdaftar lewat kode dan tidak bentrok")

	# --- interaksi tiap karya (posisi berdiri nyata, E sungguhan) ---
	for n in karya_nodes:
		var berdiri: Vector2 = n.global_position + (Vector2(0, -88 - n.global_position.y) if n.data.tipe == ExhibitData.Tipe.LUKISAN else Vector2(0, 14))
		pemain.global_position = berdiri
		await _tunggu(3)
		var terdekat: Node = null
		for a in interacting.current_interaction:
			if terdekat == null or a.global_position.distance_to(berdiri) < terdekat.global_position.distance_to(berdiri):
				terdekat = a
		_cek(interacting.current_interaction.has(n), "%s: terjangkau dari posisi berdiri (%s)" % [n.data.judul, n.interact_name])
		if terdekat != n:
			print("    (catatan: yang terdekat = %s)" % terdekat.name)
		var sebelum := ui.jumlah_catatan()
		await _tekan("interact")
		_cek(ui.sedang_terbuka() and get_tree().paused, "%s: E membuka panel label dan game pause" % n.data.judul)
		_cek(ui._teks_label.text.contains(n.data.judul) and ui._teks_label.get_parsed_text().contains(n.data.judul), "%s: label menampilkan judul" % n.data.judul)
		if n.kertas != null:
			_cek(ui._tombol_kertas.visible, "%s: tombol 'Ambil kertas terselip' muncul" % n.data.judul)
			ui._tombol_kertas.pressed.emit()
			await _tunggu()
			_cek(ui.jumlah_catatan() == sebelum + 1, "%s: kertas terselip masuk Catatan" % n.data.judul)
		else:
			_cek(not ui._tombol_kertas.visible, "%s: tidak ada tombol kertas" % n.data.judul)
		await _tekan("ui_cancel")
		_cek(not ui.sedang_terbuka() and not get_tree().paused, "%s: ui_cancel menutup panel dan melepas pause" % n.data.judul)
		await _tunggu()

	# --- kertas di lantai/pojok ---
	for n in kertas_nodes:
		pemain.global_position = n.global_position
		await _tunggu(3)
		var sebelum := ui.jumlah_catatan()
		await _tekan("interact")
		_cek(ui.jumlah_catatan() == sebelum + 1 and not n.visible, "kertas '%s' diambil dengan E dan hilang dari lantai" % n.data.teks)
		await _tunggu(3)
		_cek(not interacting.current_interaction.has(n), "kertas yang diambil keluar dari daftar interaksi")

	# --- Catatan (N) ---
	_cek(ui.jumlah_catatan() == Level3Data.CODE_LENGTH, "semua %d kertas terkumpul di Catatan" % Level3Data.CODE_LENGTH)
	await _tekan("catatan")
	_cek(ui.sedang_terbuka() and ui._panel_catatan.visible, "N membuka Catatan")
	for kr in hasil.kertas:
		_cek(ui._teks_catatan.get_parsed_text().contains(kr.teks), "Catatan memuat '%s'" % kr.teks)
	await _tekan("catatan")
	_cek(not ui.sedang_terbuka() and not get_tree().paused, "N lagi menutup Catatan")

	# --- panel kode dan pintu ---
	var panel: PanelKode = panel_nodes[0]
	var pintu: Node2D = lvl.pintu
	pemain.global_position = panel.global_position + Vector2(0, -18)
	await _tunggu(3)
	_cek(interacting.current_interaction.has(panel), "panel kode terjangkau (%s)" % panel.interact_name)
	await _tekan("interact")
	_cek(ui.sedang_terbuka() and ui._panel_kode.visible, "E membuka panel kode")
	var salah := ""
	for d in hasil.kode:
		salah += str((d + 1) % 10)
	ui._edit_kode.text = salah
	ui._kirim_kode()
	await _tunggu()
	_cek(ui.sedang_terbuka() and not panel.terbuka, "kode salah (%s): pintu tetap tertutup, panel tetap terbuka" % salah)
	ui._edit_kode.text = hasil.kode_teks()
	ui._kirim_kode()
	await _tunggu(3)
	_cek(panel.terbuka and not ui.sedang_terbuka() and not get_tree().paused, "kode benar (%s): pintu terbuka, panel menutup" % hasil.kode_teks())
	_cek(pintu.get_node("Pintu/CollisionShape2D").disabled and not pintu.visible, "collision pintu nonaktif dan pintu disembunyikan")
	_cek(lvl.get_node_or_null("PemicuKeluar") != null, "pemicu keluar dibuat di ambang pintu")

	# melangkah ke pintu tanpa next_scene: tidak crash, muncul toast
	pemain.global_position = lvl.posisi_pintu + Vector2(0, -30)
	await _tunggu(2)
	pemain.global_position = lvl.posisi_pintu
	await _tunggu(4)
	_cek(get_tree().root.get_node("InventoryUI").toast_label.text == "Level berikutnya belum tersedia", "next_scene kosong: toast 'Level berikutnya belum tersedia', tidak crash")
	lvl.queue_free()
	await _tunggu()
