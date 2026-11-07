extends Node2D
# Dipasang di root Scene/level3.tscn. Tipis: memuat karya, memanggil Level3Generator,
# lalu membangun SEMUA objek dinamis lewat kode (karya, kertas, panel kode, pintu, UI).
# Tidak ada langkah manual di editor: buka Scene/level3.tscn lalu tekan F6.

signal level_selesai

# --- Pengaturan umum ---
@export var debug_seed: int = 0                    # 0 = acak; isi angka untuk permainan yang sama
@export var allow_zero: bool = true                # false = tiap warna minimal 1 kata
@export var next_scene: PackedScene                # boleh kosong (Level 4 belum ada)
@export_dir var folder_karya: String = "res://Exhibits"

# --- Slot DINDING (lukisan): garis lurus di dinding atas ---
@export var garis_dinding_y: float = Level3Data.GARIS_DINDING_Y
@export var garis_dinding_x: Vector2 = Level3Data.RENTANG_X_DINDING
@export var jumlah_slot_dinding: int = Level3Data.JUMLAH_SLOT_DINDING

# --- Slot LANTAI (patung): grid di dalam area_lantai ---
@export var area_lantai: Rect2 = Level3Data.AREA_LANTAI
@export var kolom_lantai: int = Level3Data.KOLOM_LANTAI
@export var baris_lantai: int = Level3Data.BARIS_LANTAI

# --- Titik kertas ---
@export var area_kertas_lantai: Rect2 = Level3Data.AREA_KERTAS_LANTAI
@export var kolom_kertas_lantai: int = Level3Data.KOLOM_KERTAS_LANTAI
@export var baris_kertas_lantai: int = Level3Data.BARIS_KERTAS_LANTAI
@export var titik_pojok: Array[Vector2] = Level3Data.TITIK_POJOK
@export var area_ruang: Rect2 = Level3Data.AREA_RUANG

# --- Pintu & panel ---
@export var posisi_pintu: Vector2 = Level3Data.POSISI_PINTU
@export var posisi_panel: Vector2 = Level3Data.POSISI_PANEL

var hasil: Level3Generator.Hasil
var ui: Level3UI
var pintu: Node2D
var panel_kode: PanelKode

var _keluar_aktif := false
var _jeda_toast := false

@onready var _ysort: Node2D = $"Y-Sort"
@onready var _pemain: Node2D = $"Y-Sort/Player"

func _ready() -> void:
	var konf := _buat_konfigurasi(_muat_karya())
	hasil = Level3Generator.buat(konf)
	if not hasil.valid():
		push_warning("Level 3 tidak valid: " + ", ".join(hasil.galat))
		assert(false, "Level 3 gagal divalidasi: " + ", ".join(hasil.galat))
		return
	_bangun_ui()
	_bangun_pintu_dan_panel()
	_bangun_karya()
	_bangun_kertas()
	_cetak_debug()

# Muat SEMUA .tres di folder_karya (tangani akhiran .remap pada build ekspor).
func _muat_karya() -> Array[ExhibitData]:
	var out: Array[ExhibitData] = []
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
		if res is ExhibitData:
			out.append(res)
		else:
			push_warning("Bukan ExhibitData, dilewati: " + nama)
	return out

func _buat_konfigurasi(pool: Array[ExhibitData]) -> Level3Generator.Konfigurasi:
	var k := Level3Generator.Konfigurasi.new()
	k.pool = pool
	k.allow_zero = allow_zero
	k.seed_awal = debug_seed
	k.area_ruang = area_ruang
	k.slot_dinding = Level3Generator.slot_garis(garis_dinding_y, garis_dinding_x, jumlah_slot_dinding)
	k.slot_lantai = Level3Generator.slot_grid(area_lantai, kolom_lantai, baris_lantai)
	k.titik_kertas_lantai = Level3Generator.slot_grid(area_kertas_lantai, kolom_kertas_lantai, baris_kertas_lantai)
	k.titik_pojok = PackedVector2Array(titik_pojok)
	k.titik_terlarang = PackedVector2Array([_pemain.position, posisi_pintu, posisi_panel])
	return k

func _bangun_ui() -> void:
	ui = Level3UI.new()
	ui.name = "Level3UI"
	ui.total_karya = hasil.karya.size()
	add_child(ui)

func _bangun_pintu_dan_panel() -> void:
	pintu = PanelKode.buat_pintu(posisi_pintu)
	_ysort.add_child(pintu)
	panel_kode = PanelKode.buat(posisi_panel, hasil.kode, pintu, ui)
	panel_kode.level_selesai.connect(_on_level_selesai)
	_ysort.add_child(panel_kode)

func _bangun_karya() -> void:
	for k in hasil.karya:
		var node := KaryaPameran.buat(k.data, k.posisi, k.bbcode, ui)
		if k.indeks_kertas >= 0:
			node.kertas = hasil.kertas[k.indeks_kertas]
		_ysort.add_child(node)

func _bangun_kertas() -> void:
	for kr in hasil.kertas:
		if kr.tipe != Level3Generator.TipeKertas.TERSELIP:
			_ysort.add_child(KertasPetunjuk.buat(kr, ui))

# Kode benar: pintu sudah dibuka oleh panel. Sediakan pemicu di ambang pintu.
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

# Kode jawaban hanya dicetak pada build debug (Output editor).
func _cetak_debug() -> void:
	if not OS.is_debug_build():
		return
	print("[Level3] seed=%d (percobaan %d)  KODE JAWABAN = %s" % [hasil.seed_dipakai, hasil.percobaan, "-".join(PackedStringArray(hasil.kode.map(func(d: int) -> String: return str(d))))])
	print("[Level3] jumlah kata per warna: ", hasil.jumlah_warna)
	for kr in hasil.kertas:
		var tipe: String = Level3Generator.TipeKertas.keys()[kr.tipe]
		var lokasi := "karya " + String(hasil.karya[kr.indeks_karya].data.id) if kr.tipe == Level3Generator.TipeKertas.TERSELIP else str(kr.posisi)
		print("[Level3] kertas '%s' (%s) di %s" % [kr.teks, tipe, lokasi])
