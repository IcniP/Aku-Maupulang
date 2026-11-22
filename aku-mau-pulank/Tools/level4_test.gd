extends Node
# Skrip uji Level 4. Dijalankan sebagai scene (supaya autoload Inventory/InventoryUI/StoryUI ada):
#   godot --headless --path . res://Tools/level4_test.tscn
# 0: isi pool & data sejarah. A: generator 100 seed. N: uji negatif validator.
# M: logika mesin (semua benar -> lolos, satu keliru -> gagal). B: simulasi permainan di Scene/level4.tscn.

var _gagal := 0
var _selesai_level := false

func _ready() -> void:
	var pool := _muat_pool()
	print("=== Pool: %d karya ===" % pool.size())
	_uji_pool(pool)
	_uji_generator(pool)
	_uji_negatif(pool)
	_uji_mesin(pool)
	_uji_hardcore(pool)
	await _uji_scene()
	print("\n=== SELESAI: %s ===" % ("SEMUA LULUS" if _gagal == 0 else "%d PEMERIKSAAN GAGAL" % _gagal))
	get_tree().quit(0 if _gagal == 0 else 1)

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("  [ok]   ", pesan)
	else:
		_gagal += 1
		print("  [GAGAL] ", pesan)

func _muat_pool() -> Array[SejarahKaryaData]:
	var out: Array[SejarahKaryaData] = []
	var dir := DirAccess.open("res://Exhibits_L4")
	var nama_unik := {}
	for f in dir.get_files():
		var nama := f.trim_suffix(".remap")
		if nama.ends_with(".tres"):
			nama_unik[nama] = true
	var urut: Array = nama_unik.keys()
	urut.sort()
	for nama in urut:
		var res := load("res://Exhibits_L4/" + nama)
		if res is SejarahKaryaData:
			out.append(res)
	return out

# ------------------------------------------------------------------ 0: pool

func _uji_pool(pool: Array[SejarahKaryaData]) -> void:
	print("\n=== 0. Isi pool Exhibits_L4/ ===")
	var n_min := 0
	var n_luk := 0
	var semua_ok := true
	for k in pool:
		if k.tipe == SejarahKaryaData.Tipe.MINIATUR:
			n_min += 1
		else:
			n_luk += 1
		var g := SejarahGenerator.validasi_data(k)
		var n_kata := SejarahGenerator.teks_polos(k.teks_label).strip_edges().split(" ", false).size()
		print("  %-40s %-8s %2d kata  %s" % [k.judul, "miniatur" if k.tipe == SejarahKaryaData.Tipe.MINIATUR else "lukisan", n_kata, "OK" if g.is_empty() else "MASALAH: " + ", ".join(g)])
		if not g.is_empty():
			semua_ok = false
	_cek(n_min == 8 and n_luk == 6, "pool lengkap: %d miniatur + %d lukisan (target 8 + 6)" % [n_min, n_luk])
	_cek(n_min >= SejarahData.JUMLAH_MINIATUR and n_luk >= SejarahData.JUMLAH_LUKISAN, "pool cukup untuk tampil %d miniatur + %d lukisan" % [SejarahData.JUMLAH_MINIATUR, SejarahData.JUMLAH_LUKISAN])
	_cek(semua_ok, "tiap karya: 50-70 kata, tepat 3 tahun, 3 fakta, 2 varian salah per fakta, 2 tak terbukti")
	var g_pool := SejarahGenerator.validasi_pool(pool)
	_cek(g_pool.is_empty(), "kata kunci unik lintas label (satu peristiwa hanya di satu label)" + ("" if g_pool.is_empty() else ": " + ", ".join(g_pool)))
	var kap := SejarahGenerator.kapasitas(pool)
	print("  kapasitas: BENAR+SALAH maks %d fakta, TIDAK ADA minimal %d pernyataan" % [kap["benar_salah"], kap["tidak_ada_min"]])
	_cek(kap["benar_salah"] >= 14 and kap["tidak_ada_min"] >= 6, "pool cukup untuk mode hardcore 20 potongan")

# ------------------------------------------------------------------ A: generator

func _uji_generator(pool: Array[SejarahKaryaData]) -> void:
	print("\n=== A. Generator, 100 seed ===")
	var gagal_seed: Array[int] = []
	var butuh_ulang: Array[int] = []
	var min_k := [99, 99, 99]
	var maks_k := [0, 0, 0]
	var jenis := [0, 0, 0, 0]
	var posisi_kardus := {}
	var karya_dipakai := {}
	for s in range(1, 101):
		var konf := SejarahGenerator.konfigurasi_standar(pool, s)
		var h := SejarahGenerator.buat(konf)
		var galat := SejarahGenerator.validasi(konf, h)   # validasi ulang di luar generator
		var ok := h.valid() and galat.is_empty()
		var komp := h.komposisi()
		var ids: Array[String] = []
		for k in h.karya:
			ids.append(String(k.data.id).substr(0, 6))
			karya_dipakai[k.data.id] = true
		print("seed %3d | B/S/T %d/%d/%d | total %d | kardus %s | karya %s | percobaan %d | %s" % [s, komp[0], komp[1], komp[2], h.potongan.size(), str(h.posisi_kardus), ",".join(ids), h.percobaan, "LOLOS" if ok else "GAGAL " + ", ".join(h.galat)])
		if not ok:
			gagal_seed.append(s)
		if h.percobaan > 1:
			butuh_ulang.append(s)
		for i in 3:
			min_k[i] = mini(min_k[i], komp[i])
			maks_k[i] = maxi(maks_k[i], komp[i])
		for p in h.potongan:
			jenis[p.jenis] += 1
		posisi_kardus[h.posisi_kardus] = true
	print("--- ringkasan ---")
	print("seed gagal setelah %d percobaan: %s" % [SejarahData.MAKS_PERCOBAAN, str(gagal_seed) if not gagal_seed.is_empty() else "tidak ada"])
	print("seed yang butuh acak ulang: %s" % (str(butuh_ulang) if not butuh_ulang.is_empty() else "tidak ada"))
	print("jumlah per kategori: BENAR %d-%d, SALAH %d-%d, TIDAK ADA %d-%d" % [min_k[0], maks_k[0], min_k[1], maks_k[1], min_k[2], maks_k[2]])
	print("jenis potongan (benar/salah/tak terbukti/fakta tak tampil): %s" % str(jenis))
	print("posisi kardus berbeda: %d | karya yang pernah tampil: %d dari %d" % [posisi_kardus.size(), karya_dipakai.size(), pool.size()])
	_cek(gagal_seed.is_empty(), "100 seed lolos validasi (pool %d karya)" % pool.size())
	_cek(min_k[0] >= 4 and min_k[1] >= 4 and min_k[2] >= 4 and maks_k[0] <= 7 and maks_k[1] <= 7 and maks_k[2] <= 7, "tiap kategori selalu 4-7 potongan")
	_cek(jenis[2] > 0 and jenis[3] > 0, "TIDAK ADA memakai kedua sumber (tak terbukti dan fakta karya tak tampil)")
	var a := SejarahGenerator.buat(SejarahGenerator.konfigurasi_standar(pool, 42))
	var b := SejarahGenerator.buat(SejarahGenerator.konfigurasi_standar(pool, 42))
	var sama := a.potongan.size() == b.potongan.size()
	for i in a.potongan.size():
		if a.potongan[i].teks != b.potongan[i].teks:
			sama = false
	_cek(sama, "seed sama -> hasil sama")

# ------------------------------------------------------------------ N: uji negatif validator

func _uji_negatif(pool: Array[SejarahKaryaData]) -> void:
	print("\n=== N. Uji negatif: validator harus menolak hasil yang dirusak ===")
	var konf := SejarahGenerator.konfigurasi_standar(pool, 7)
	var dasar := SejarahGenerator.buat(konf)
	_cek(SejarahGenerator.validasi(konf, dasar).is_empty(), "hasil dasar valid")

	var h := SejarahGenerator.buat(konf)
	for p in h.potongan:
		if p.kategori == SejarahData.Kategori.TIDAK_ADA:
			p.kata_kunci = h.karya[0].data.fakta[0].kata_kunci   # kata kunci ada di label tampil
			break
	_cek(not SejarahGenerator.validasi(konf, h).is_empty(), "TIDAK ADA yang kata kuncinya ada di label ditolak")

	h = SejarahGenerator.buat(konf)
	for p in h.potongan:
		if p.kategori == SejarahData.Kategori.BENAR:
			p.kategori = SejarahData.Kategori.SALAH
	_cek(not SejarahGenerator.validasi(konf, h).is_empty(), "komposisi/jenis tidak cocok ditolak")

	h = SejarahGenerator.buat(konf)
	for p in h.potongan:
		if p.kategori == SejarahData.Kategori.BENAR:
			p.karya_id = &"karya_tidak_tampil"
			break
	_cek(not SejarahGenerator.validasi(konf, h).is_empty(), "BENAR dari karya yang tidak tampil ditolak")

	h = SejarahGenerator.buat(konf)
	h.potongan[1].teks = h.potongan[0].teks
	_cek(not SejarahGenerator.validasi(konf, h).is_empty(), "potongan ganda ditolak")

	h = SejarahGenerator.buat(konf)
	h.potongan.pop_back()
	_cek(not SejarahGenerator.validasi(konf, h).is_empty(), "jumlah potongan kurang ditolak")

	h = SejarahGenerator.buat(konf)
	h.posisi_kardus = h.karya[0].posisi
	_cek(not SejarahGenerator.validasi(konf, h).is_empty(), "kardus di atas karya ditolak")

	# data rusak harus dibuang dari pool (muncul WARNING yang disengaja di bawah ini)
	var rusak: SejarahKaryaData = pool[0].duplicate(true)
	rusak.id = &"rusak"
	rusak.teks_label = "Terlalu pendek."
	var campur: Array[SejarahKaryaData] = [pool[0], rusak]
	_cek(SejarahGenerator.bersihkan_pool(campur).size() == 1 and not SejarahGenerator.validasi_data(rusak).is_empty(), "karya dengan data rusak dibuang dari pool")

# ------------------------------------------------------------------ M: logika mesin

func _jawab_semua(m: SejarahMesinLogika, salah_indeks: int = -1) -> void:
	for i in m.potongan.size():
		var k: int = m.potongan[i].kategori
		if i == salah_indeks:
			k = (k + 1) % 3
		m.masukkan(i, k)

func _uji_mesin(pool: Array[SejarahKaryaData]) -> void:
	print("\n=== M. Logika mesin (RefCounted) ===")
	var h := SejarahGenerator.buat(SejarahGenerator.konfigurasi_standar(pool, 11))
	var m := SejarahMesinLogika.new(h.potongan, 5)
	_cek(m.masukkan(0, 0) == false, "sebelum kardus diambil, mesin menolak potongan")
	_cek(m.ambil_dari_kardus() and m.jumlah_tumpukan() == SejarahData.JUMLAH_POTONGAN, "kardus diambil: %d potongan masuk tumpukan" % SejarahData.JUMLAH_POTONGAN)
	_cek(m.ambil_dari_kardus() == false, "kardus kedua kali: tidak ada lagi (kosong)")
	_cek(m.masukkan(0, h.potongan[0].kategori) and m.masukkan(0, 0) == false, "potongan yang sudah masuk tidak bisa dimasukkan/ditarik lagi")
	_cek(m.periksa()["salah"] == -1 and not m.periksa()["lolos"], "belum semua masuk -> belum diperiksa")

	m = SejarahMesinLogika.new(h.potongan, 5)
	m.ambil_dari_kardus()
	_jawab_semua(m)
	var r := m.periksa()
	_cek(m.semua_masuk() and r["lolos"] and r["salah"] == 0, "semua jawaban benar -> LOLOS")

	for idx in [0, 7, 14]:
		m = SejarahMesinLogika.new(h.potongan, 5)
		m.ambil_dari_kardus()
		_jawab_semua(m, idx)
		r = m.periksa()
		_cek(not r["lolos"] and r["salah"] == 1, "satu keliru (potongan %d) -> GAGAL, terdeteksi 1" % (idx + 1))

	m = SejarahMesinLogika.new(h.potongan, 5)
	m.ambil_dari_kardus()
	for i in h.potongan.size():
		m.masukkan(i, (h.potongan[i].kategori + 1) % 3)
	_cek(m.periksa()["salah"] == h.potongan.size(), "semua keliru -> GAGAL (%d salah)" % h.potongan.size())
	m.keluarkan_semua()
	var urut := m.tumpukan.duplicate()
	urut.sort()
	var lengkap := true
	for i in urut.size():
		if urut[i] != i:
			lengkap = false
	_cek(m.jumlah_tumpukan() == h.potongan.size() and lengkap and m.jumlah_dimasukkan() == 0, "setelah gagal: semua %d potongan kembali ke tumpukan, mesin kosong" % h.potongan.size())
	_jawab_semua(m)
	_cek(m.periksa()["lolos"], "ulang dari awal dengan jawaban benar -> LOLOS")

# Hardcore nanti: 20 potongan. Hanya uji generator: pool sekarang harus sudah cukup,
# dengan batas bawaan 4-7 per kategori (mode hardcore TIDAK diaktifkan di game).
func _uji_hardcore(pool: Array[SejarahKaryaData]) -> void:
	print("\n=== H. Kesiapan 20 potongan (hanya uji generator, tidak mengubah JUMLAH_POTONGAN) ===")
	var gagal: Array[int] = []
	var komposisi_unik := {}
	for s in range(1, 101):
		var konf := SejarahGenerator.konfigurasi_standar(pool, s)
		konf.jumlah_potongan = 20
		var h := SejarahGenerator.buat(konf)
		var ok := h.valid() and h.potongan.size() == 20 and SejarahGenerator.validasi(konf, h).is_empty()
		if not ok:
			gagal.append(s)
		komposisi_unik[str(h.komposisi())] = true
	print("seed gagal: %s | komposisi berbeda: %s" % [str(gagal) if not gagal.is_empty() else "tidak ada", ", ".join(komposisi_unik.keys())])
	_cek(gagal.is_empty(), "100 seed dengan 20 potongan lolos validasi (kategori 4-7)")
	_cek(SejarahData.JUMLAH_POTONGAN == 15, "JUMLAH_POTONGAN di game tetap 15")

# ------------------------------------------------------------------ B: simulasi scene

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

func _toast() -> String:
	return get_tree().root.get_node("InventoryUI").toast_label.text

# Masukkan semua potongan lewat tombol UI. salah_n = jumlah potongan yang sengaja dikeliru.
func _isi_mesin(ui: SejarahUI, salah_n: int) -> void:
	var sudah_salah := 0
	var hitung := 0
	while ui.logika.jumlah_tumpukan() > 0 and ui.logika.semua_masuk() == false:
		ui._daftar.select(0)
		ui._saat_dipilih(0)
		var idx: int = ui._daftar.get_item_metadata(0)
		var k: int = ui.logika.potongan[idx].kategori
		if sudah_salah < salah_n:
			k = (k + 1) % 3
			sudah_salah += 1
		ui._tombol_kategori[k].pressed.emit()
		hitung += 1
		if hitung == 1:
			_cek(ui._hitung_mesin.text == "1/%d dimasukkan" % SejarahData.JUMLAH_POTONGAN and ui.logika.jumlah_tumpukan() == SejarahData.JUMLAH_POTONGAN - 1, "penghitung 'n/15 dimasukkan' bertambah dan potongan keluar dari daftar")
		if ui.logika.semua_masuk():
			break

func _uji_scene() -> void:
	print("\n=== B. Simulasi permainan di Scene/level4.tscn ===")
	var lvl: Node = load("res://Scene/level4.tscn").instantiate()
	add_child(lvl)
	await _tunggu(3)
	var hasil: SejarahGenerator.Hasil = lvl.hasil
	var ui: SejarahUI = lvl.ui
	var logika: SejarahMesinLogika = lvl.logika
	var pemain: Player = lvl.get_node("Y-Sort/Player")
	var interacting: Node = pemain.get_node("interacting")
	ui.jeda_periksa = 0.3
	lvl.level_selesai.connect(func() -> void: _selesai_level = true)
	_cek(hasil != null and hasil.valid(), "level4.tscn memuat dan hasil generator valid")
	_cek(ui != null and logika != null, "SejarahUI dan logika dibuat lewat kode")

	var karya_nodes := get_tree().get_nodes_in_group("sejarah_karya")
	var kardus: SejarahKardus = lvl.kardus
	var mesin: SejarahMesin = lvl.mesin
	var kategori_node: Node = get_tree().get_nodes_in_group("sejarah_kertas_kategori")[0]
	var n_min := 0
	var n_luk := 0
	for n in karya_nodes:
		if n.data.tipe == SejarahKaryaData.Tipe.MINIATUR:
			n_min += 1
		else:
			n_luk += 1
	_cek(karya_nodes.size() == 7 and n_min == 4 and n_luk == 3, "7 karya muncul (4 miniatur + 3 lukisan)")
	var layer_ok := true
	for n in karya_nodes + [kardus, mesin, kategori_node]:
		if n.collision_layer != 2 or n.collision_mask != 0:
			layer_ok = false
	_cek(layer_ok, "semua Interactable di collision layer 2")
	var badan_ok := true
	var nama_ok := true
	for n in karya_nodes:
		var punya := false
		for c in n.get_children():
			if c is StaticBody2D:
				punya = true
		if (n.data.tipe == SejarahKaryaData.Tipe.MINIATUR) != punya:
			badan_ok = false
		if n.interact_name != ("Periksa Miniatur" if n.data.tipe == SejarahKaryaData.Tipe.MINIATUR else "Periksa Lukisan"):
			nama_ok = false
	_cek(badan_ok, "miniatur punya StaticBody2D, lukisan tidak")
	_cek(nama_ok, "interact_name 'Periksa Miniatur' / 'Periksa Lukisan'")
	var ruang := pemain.get_world_2d().direct_space_state
	var padat := true
	for n in karya_nodes:
		if n.data.tipe == SejarahKaryaData.Tipe.MINIATUR:
			var q := PhysicsPointQueryParameters2D.new()
			q.position = n.global_position + Vector2(0, -3)
			q.collide_with_bodies = true
			if ruang.intersect_point(q).is_empty():
				padat = false
	_cek(padat, "dasar miniatur terdeteksi sebagai benda padat")
	var bentrok := false
	for aksi in InputMap.get_actions():
		if aksi == SejarahUI.AKSI_TUMPUKAN:
			continue
		for ev in InputMap.action_get_events(aksi):
			if ev is InputEventKey and ev.physical_keycode == KEY_N:
				bentrok = true
	_cek(InputMap.has_action(SejarahUI.AKSI_TUMPUKAN) and not bentrok, "aksi tumpukan (N) terdaftar lewat kode dan tidak bentrok")

	# --- tiap karya: E membuka label, memuat judul & tahun tebal, tanpa warna ---
	for n in karya_nodes:
		var berdiri: Vector2 = n.global_position + (Vector2(0, -88 - n.global_position.y) if n.data.tipe == SejarahKaryaData.Tipe.LUKISAN else Vector2(0, 14))
		pemain.global_position = berdiri
		await _tunggu(3)
		_cek(interacting.current_interaction.has(n), "%s: terjangkau dari posisi berdiri (%s)" % [n.data.judul, n.interact_name])
		await _tekan("interact")
		_cek(ui.sedang_terbuka() and get_tree().paused and ui._teks_label.get_parsed_text().contains(n.data.judul), "%s: E membuka panel label (game pause) dan judul tampil" % n.data.judul)
		_cek(ui._teks_label.text.contains("[b]") and not ui._teks_label.text.contains("[color"), "%s: tahun dicetak tebal, tidak ada kata berwarna" % n.data.judul)
		await _tekan("ui_cancel")
		_cek(not ui.sedang_terbuka() and not get_tree().paused, "%s: ui_cancel menutup panel dan melepas pause" % n.data.judul)
		await _tunggu()

	# --- mesin sebelum kardus diambil ---
	pemain.global_position = mesin.global_position + Vector2(0, -18)
	await _tunggu(3)
	_cek(interacting.current_interaction.has(mesin), "mesin terjangkau (%s)" % mesin.interact_name)
	await _tekan("interact")
	_cek(not ui.sedang_terbuka() and _toast().begins_with("Belum ada potongan kertas"), "mesin sebelum kardus diambil: toast, panel tidak terbuka")

	# --- kertas kategori ---
	pemain.global_position = kategori_node.global_position + Vector2(0, -16)
	await _tunggu(3)
	_cek(interacting.current_interaction.has(kategori_node) and kategori_node.interact_name == "Baca catatan", "kertas kategori terjangkau (Baca catatan)")
	await _tekan("interact")
	var teks_kat: String = ui._panel_kategori.get_child(0).get_child(1).get_parsed_text()
	_cek(ui.sedang_terbuka() and teks_kat.contains("BENAR") and teks_kat.contains("SALAH") and teks_kat.contains("TIDAK ADA") and teks_kat.contains("HANYA dari label"), "kertas kategori menampilkan aturan BENAR/SALAH/TIDAK ADA")
	await _tekan("ui_cancel")
	_cek(not ui.sedang_terbuka(), "kertas kategori ditutup dengan ui_cancel")

	# --- kardus ---
	pemain.global_position = kardus.global_position + Vector2(0, 10)
	await _tunggu(3)
	_cek(interacting.current_interaction.has(kardus), "kardus terjangkau (%s)" % kardus.interact_name)
	await _tekan("interact")
	_cek(_toast() == "Kamu mengambil %d potongan kertas" % SejarahData.JUMLAH_POTONGAN and logika.jumlah_tumpukan() == SejarahData.JUMLAH_POTONGAN, "kardus: toast 'Kamu mengambil 15 potongan kertas', 15 potongan di tumpukan")
	_cek(kardus.interact_name == "Kardus kosong", "kardus menjadi 'Kardus kosong'")
	await _tunggu(3)
	await _tekan("interact")
	_cek(_toast() == "Kardus ini sudah kosong" and logika.jumlah_tumpukan() == SejarahData.JUMLAH_POTONGAN, "kardus kedua kali: tidak menambah potongan")
	_cek(get_tree().root.get_node("Inventory") != null and not _inventori_berubah(), "tumpukan tidak memakai slot Inventory")

	# --- tumpukan (N) ---
	await _tekan(SejarahUI.AKSI_TUMPUKAN)
	var teks_tumpukan := ui._teks_tumpukan.get_parsed_text()
	_cek(ui.sedang_terbuka() and ui._panel_tumpukan.visible and teks_tumpukan.contains(hasil.potongan[0].teks) and teks_tumpukan.contains(hasil.potongan[14].teks), "N membuka tumpukan dan memuat semua potongan")
	await _tekan(SejarahUI.AKSI_TUMPUKAN)
	_cek(not ui.sedang_terbuka() and not get_tree().paused, "N lagi menutup tumpukan")

	# --- mesin, putaran 1: ADA yang keliru ---
	pemain.global_position = mesin.global_position + Vector2(0, -18)
	await _tunggu(3)
	await _tekan("interact")
	_cek(ui.sedang_terbuka() and ui._panel_mesin.visible and ui._daftar.item_count == SejarahData.JUMLAH_POTONGAN, "mesin terbuka: daftar %d potongan, pilih satu menampilkan teksnya" % SejarahData.JUMLAH_POTONGAN)
	_cek(ui._teks_pilihan.get_parsed_text().contains(hasil.potongan[ui._daftar.get_item_metadata(0)].teks.substr(0, 20)), "potongan terpilih tampil jelas")
	_isi_mesin(ui, 1)
	_cek(ui._status_mesin.text == "Memeriksa...", "setelah potongan ke-15: tampil 'Memeriksa...'")
	await _tekan("ui_cancel")
	_cek(ui.sedang_terbuka(), "ui_cancel diabaikan saat 'Memeriksa...'")
	await get_tree().create_timer(0.6, true).timeout   # timer tetap jalan saat pause
	await _tunggu()
	_cek(not ui.sedang_terbuka() and not mesin.terbuka, "1 potongan keliru: pintu TIDAK terbuka, panel menutup")
	_cek(_toast() == "Ada yang tidak sesuai! Semua kertas dikeluarkan.", "toast tanpa menyebut jumlah/potongan yang salah")
	_cek(logika.jumlah_tumpukan() == SejarahData.JUMLAH_POTONGAN and logika.jumlah_dimasukkan() == 0, "semua 15 potongan kembali ke tumpukan pemain")
	_cek(not lvl.pintu.get_node("Pintu/CollisionShape2D").disabled and lvl.pintu.visible, "pintu masih tertutup")

	# --- putaran 2: tampilkan_jumlah_salah = true, 2 keliru ---
	mesin.tampilkan_jumlah_salah = true
	await _tekan("interact")
	_cek(ui.sedang_terbuka() and ui._panel_mesin.visible, "mesin bisa dipakai lagi setelah gagal")
	_isi_mesin(ui, 2)
	await get_tree().create_timer(0.6, true).timeout
	await _tunggu()
	_cek(not mesin.terbuka and _toast().contains("(2 keliru)"), "@export tampilkan_jumlah_salah=true: toast menyebut '(2 keliru)'")
	mesin.tampilkan_jumlah_salah = false

	# --- putaran 3: semua benar ---
	await _tekan("interact")
	_isi_mesin(ui, 0)
	await get_tree().create_timer(0.6, true).timeout
	await _tunggu(3)
	_cek(mesin.terbuka and _selesai_level and not ui.sedang_terbuka() and not get_tree().paused, "semua benar: pintu terbuka, signal level_selesai, panel menutup")
	_cek(_toast() == "Pintu terbuka!", "toast 'Pintu terbuka!'")
	_cek(lvl.pintu.get_node("Pintu/CollisionShape2D").disabled and not lvl.pintu.visible, "collision pintu nonaktif dan pintu disembunyikan")
	_cek(lvl.get_node_or_null("PemicuKeluar") != null, "pemicu keluar dibuat di ambang pintu")
	await _tunggu(3)
	_cek(not interacting.current_interaction.has(mesin), "mesin keluar dari daftar interaksi setelah pintu terbuka")

	# melangkah ke pintu tanpa next_scene: tidak crash, muncul toast
	pemain.global_position = lvl.posisi_pintu + Vector2(0, -30)
	await _tunggu(2)
	pemain.global_position = lvl.posisi_pintu
	await _tunggu(4)
	_cek(_toast() == "Level berikutnya belum tersedia", "next_scene kosong: toast 'Level berikutnya belum tersedia', tidak crash")
	lvl.queue_free()
	await _tunggu()

func _inventori_berubah() -> bool:
	# Inventory = 3 slot ItemData; tumpukan potongan tidak boleh masuk ke sana
	var inv := get_tree().root.get_node("Inventory")
	for s in inv.items:
		if s != null:
			return true
	return false
