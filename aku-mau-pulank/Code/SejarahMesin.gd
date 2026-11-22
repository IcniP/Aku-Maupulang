class_name SejarahMesin
extends Interactable
# Mesin BENAR / SALAH / TIDAK ADA di samping pintu + logika pintu. Dibuat lewat kode oleh level4_manager.gd.

signal level_selesai

var logika: SejarahMesinLogika
var pintu: Node2D                       # node pintu (punya anak "Pintu/CollisionShape2D")
var ui: SejarahUI
var tampilkan_jumlah_salah := false     # diisi manager dari @export
var terbuka := false
var _bentuk: CollisionShape2D

# Pintu placeholder: kotak berwarna + StaticBody2D yang menghalangi, dengan tulisan penanda.
static func buat_pintu(pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.name = "PintuKeluar"
	n.position = pos
	var badan := StaticBody2D.new()
	badan.name = "Pintu"
	n.add_child(badan)
	var kotak := Polygon2D.new()
	kotak.color = Color(0.3, 0.2, 0.1)
	kotak.polygon = PackedVector2Array([Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)])
	badan.add_child(kotak)
	var bentuk := CollisionShape2D.new()
	bentuk.name = "CollisionShape2D"
	var persegi := RectangleShape2D.new()
	persegi.size = Vector2(24, 24)
	bentuk.shape = persegi
	badan.add_child(bentuk)
	n.add_child(tulisan("PINTU - menuju level berikutnya", Vector2(-26, -44), 52))
	return n

static func buat(pos: Vector2, logika_mesin: SejarahMesinLogika, pintu_node: Node2D, panel_ui: SejarahUI) -> SejarahMesin:
	var n := SejarahMesin.new()
	n.name = "Mesin"
	n.position = pos
	n.logika = logika_mesin
	n.pintu = pintu_node
	n.ui = panel_ui
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("sejarah_mesin")

func _bangun() -> void:
	collision_layer = 2
	collision_mask = 0
	interact_name = "Gunakan mesin"
	var badan_visual := Polygon2D.new()
	badan_visual.color = Color(0.25, 0.28, 0.35)
	badan_visual.polygon = PackedVector2Array([Vector2(-9, -14), Vector2(9, -14), Vector2(9, 8), Vector2(-9, 8)])
	add_child(badan_visual)
	var layar := Polygon2D.new()
	layar.color = Color(0.3, 0.9, 0.5)
	layar.polygon = PackedVector2Array([Vector2(-6, -11), Vector2(6, -11), Vector2(6, -4), Vector2(-6, -4)])
	add_child(layar)
	add_child(tulisan("MESIN BENAR / SALAH / TIDAK ADA", Vector2(-24, -62), 48))
	var badan := StaticBody2D.new()
	var kb := CollisionShape2D.new()
	var rb := RectangleShape2D.new()
	rb.size = Vector2(16, 8)
	kb.shape = rb
	kb.position = Vector2(0, 4)
	badan.add_child(kb)
	add_child(badan)
	_bentuk = CollisionShape2D.new()
	var lingkar := CircleShape2D.new()
	lingkar.radius = 26.0
	_bentuk.shape = lingkar
	_bentuk.position = Vector2(0, -4)
	add_child(_bentuk)

# Tulisan placeholder berkontras (putih + outline hitam), dipakai juga oleh kertas kategori.
static func tulisan(teks: String, pos: Vector2, lebar: float) -> Label:
	var l := Label.new()
	l.text = teks
	l.position = pos
	l.size = Vector2(lebar, 10)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 5
	l.add_theme_font_size_override("font_size", 7)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l

func interact() -> void:
	if terbuka or ui == null or logika == null:
		return
	if not logika.kardus_diambil:
		InventoryUI.show_message("Belum ada potongan kertas. Ambil dari kardus dulu.")
		return
	ui.buka_mesin()
	await ui.closed

# Dipanggil UI setelah potongan terakhir dimasukkan dan "Memeriksa..." selesai.
func selesai_memasukkan() -> bool:
	var hasil := logika.periksa()
	if hasil["lolos"]:
		_buka_pintu()
		return true
	logika.keluarkan_semua()
	var pesan := "Ada yang tidak sesuai! Semua kertas dikeluarkan."
	if tampilkan_jumlah_salah:
		pesan += " (%d keliru)" % hasil["salah"]
	InventoryUI.show_message(pesan)
	return false

func _buka_pintu() -> void:
	terbuka = true
	is_interactable = false
	if pintu != null:
		pintu.get_node("Pintu/CollisionShape2D").set_deferred("disabled", true)
		pintu.hide()
	_bentuk.set_deferred("disabled", true)   # keluar dari daftar interaksi pemain
	InventoryUI.show_message("Pintu terbuka!")
	level_selesai.emit()
