extends Node2D
# Dipasang di root Scene/level4.tscn. Tipis: memuat karya sejarah, memanggil SejarahGenerator,
# lalu membangun SEMUA objek dinamis lewat kode (karya, kardus, mesin, kertas kategori, pintu, UI).
# Tidak ada langkah manual di editor: buka Scene/level4.tscn lalu tekan F6.

signal level_selesai

# --- Pengaturan umum ---
@export var debug_seed: int = 0                    # 0 = acak; isi angka untuk permainan yang sama
@export var next_scene: PackedScene                # boleh kosong (Level 5 belum ada)
@export var tampilkan_jumlah_salah := false        # true = toast menyebut jumlah potongan yang keliru
@export var jeda_periksa: float = 1.2              # lama tulisan "Memeriksa..." (detik)
@export_dir var folder_karya: String = "res://Exhibits_L4"

# --- Slot DINDING (lukisan) ---
@export var garis_dinding_y: float = SejarahData.GARIS_DINDING_Y
@export var garis_dinding_x: Vector2 = SejarahData.RENTANG_X_DINDING
@export var jumlah_slot_dinding: int = SejarahData.JUMLAH_SLOT_DINDING

# --- Slot LANTAI (miniatur) ---
@export var area_lantai: Rect2 = SejarahData.AREA_LANTAI
@export var kolom_lantai: int = SejarahData.KOLOM_LANTAI
@export var baris_lantai: int = SejarahData.BARIS_LANTAI

# --- Titik kardus ---
@export var area_kardus: Rect2 = SejarahData.AREA_KARDUS
@export var kolom_kardus: int = SejarahData.KOLOM_KARDUS
@export var baris_kardus: int = SejarahData.BARIS_KARDUS
@export var titik_pojok: Array[Vector2] = SejarahData.TITIK_POJOK
@export var area_ruang: Rect2 = SejarahData.AREA_RUANG

# --- Pintu, mesin, kertas kategori ---
@export var posisi_pintu: Vector2 = SejarahData.POSISI_PINTU
@export var posisi_mesin: Vector2 = SejarahData.POSISI_MESIN
@export var posisi_kertas_kategori: Vector2 = SejarahData.POSISI_KERTAS_KATEGORI

var hasil: SejarahGenerator.Hasil
var logika: SejarahMesinLogika
var ui: SejarahUI
var pintu: Node2D
var mesin: SejarahMesin
var kardus: SejarahKardus

var _keluar_aktif := false
var _jeda_toast := false

@onready var _ysort: Node2D = $"Y-Sort"
@onready var _pemain: Node2D = $"Y-Sort/Player"

func _ready() -> void:
	var pool := SejarahGenerator.bersihkan_pool(_muat_karya())
	var galat_pool := SejarahGenerator.validasi_pool(pool)
	if not galat_pool.is_empty():
		push_warning("Data sejarah Level 4 bermasalah: " + ", ".join(galat_pool))
	hasil = SejarahGenerator.buat(_buat_konfigurasi(pool))
	if not hasil.valid():
		push_warning("Level 4 tidak valid: " + ", ".join(hasil.galat))
		assert(false, "Level 4 gagal divalidasi: " + ", ".join(hasil.galat))
		return
	logika = SejarahMesinLogika.new(hasil.potongan, hasil.seed_dipakai)
	_bangun_ui()
	_bangun_pintu_mesin_kategori()
	_bangun_karya()
	_bangun_kardus()
	_cetak_debug()

# Muat SEMUA .tres di folder_karya (tangani akhiran .remap pada build ekspor).
func _muat_karya() -> Array[SejarahKaryaData]:
	var out: Array[SejarahKaryaData] = []
	var dir := DirAccess.open(folder_karya)
	if dir == null:
		push_warning("Folder karya tidak bisa dibuka: " + folder_karya)
		return out
	var nama_unik := {}
	for f in dir.get_files():
		var nama := f.trim_suffix(".remap")
		if nama.ends_with(".tres") or nama.ends_with(".res"):
			nama_unik[nama] = true
	var urut: Array = nama_unik.keys()
	urut.sort()   # urutan tetap supaya debug_seed konsisten
	for nama in urut:
		var res := load(folder_karya.path_join(nama))
		if res is SejarahKaryaData:
			out.append(res)
		else:
			push_warning("Bukan SejarahKaryaData, dilewati: " + nama)
	return out

func _buat_konfigurasi(pool: Array[SejarahKaryaData]) -> SejarahGenerator.Konfigurasi:
	var k := SejarahGenerator.Konfigurasi.new()
	k.pool = pool
	k.seed_awal = debug_seed
	k.area_ruang = area_ruang
	k.slot_dinding = SejarahGenerator.slot_garis(garis_dinding_y, garis_dinding_x, jumlah_slot_dinding)
	k.slot_lantai = SejarahGenerator.slot_grid(area_lantai, kolom_lantai, baris_lantai)
	k.titik_kardus = SejarahGenerator.slot_grid(area_kardus, kolom_kardus, baris_kardus)
	k.titik_kardus.append_array(PackedVector2Array(titik_pojok))
	var terlarang := PackedVector2Array([_pemain.position, posisi_pintu, posisi_mesin, posisi_kertas_kategori])
	terlarang.append_array(PackedVector2Array(SejarahData.ZONA_TULISAN))
	k.titik_terlarang = terlarang
	return k

func _bangun_ui() -> void:
	ui = SejarahUI.new()
	ui.name = "SejarahUI"
	ui.total_karya = hasil.karya.size()
	ui.logika = logika
	ui.jeda_periksa = jeda_periksa
	add_child(ui)

func _bangun_pintu_mesin_kategori() -> void:
	pintu = SejarahMesin.buat_pintu(posisi_pintu)
	_ysort.add_child(pintu)
	mesin = SejarahMesin.buat(posisi_mesin, logika, pintu, ui)
	mesin.tampilkan_jumlah_salah = tampilkan_jumlah_salah
	mesin.level_selesai.connect(_on_level_selesai)
	ui.mesin_node = mesin
	_ysort.add_child(mesin)
	_ysort.add_child(SejarahKertasKategori.buat(posisi_kertas_kategori, ui))

func _bangun_karya() -> void:
	for k in hasil.karya:
		_ysort.add_child(SejarahKarya.buat(k.data, k.posisi, ui))

func _bangun_kardus() -> void:
	kardus = SejarahKardus.buat(hasil.posisi_kardus, logika)
	_ysort.add_child(kardus)

# Semua potongan benar: pintu sudah dibuka oleh mesin. Sediakan pemicu di ambang pintu.
func _on_level_selesai() -> void:
	level_selesai.emit()
	if _keluar_aktif:
		return
	_keluar_aktif = true
	var pemicu := Area2D.new()
	pemicu.name = "PemicuKeluar"
	pemicu.collision_layer = 0
	pemicu.collision_mask = 1   # layer pemain
	pemicu.position = posisi_pintu
	var bentuk := CollisionShape2D.new()
	var kotak := RectangleShape2D.new()
	kotak.size = Vector2(28, 28)
	bentuk.shape = kotak
	pemicu.add_child(bentuk)
	pemicu.body_entered.connect(_on_masuk_pintu)
	add_child(pemicu)

func _on_masuk_pintu(body: Node2D) -> void:
	if not (body is Player):
		return
	pindah_level()

# Pindah ke next_scene; bila kosong cukup tampilkan toast (tidak crash).
func pindah_level() -> void:
	if next_scene == null:
		if not _jeda_toast:
			_jeda_toast = true
			InventoryUI.show_message("Level berikutnya belum tersedia")
			get_tree().create_timer(2.5).timeout.connect(func() -> void: _jeda_toast = false)
		return
	get_tree().change_scene_to_packed.call_deferred(next_scene)

# Kunci jawaban hanya dicetak pada build debug (Output editor).
func _cetak_debug() -> void:
	if not OS.is_debug_build():
		return
	var komp := hasil.komposisi()
	print("[Level4] seed=%d (percobaan %d)  BENAR=%d SALAH=%d TIDAK ADA=%d" % [hasil.seed_dipakai, hasil.percobaan, komp[0], komp[1], komp[2]])
	print("[Level4] karya tampil: ", ", ".join(PackedStringArray(hasil.karya.map(func(k: SejarahGenerator.Karya) -> String: return String(k.data.id)))))
	print("[Level4] KUNCI JAWABAN (potongan -> kategori):")
	for i in hasil.potongan.size():
		var p := hasil.potongan[i]
		print("  %2d. [%-9s] %s" % [i + 1, SejarahData.nama_kategori(p.kategori), p.teks])
