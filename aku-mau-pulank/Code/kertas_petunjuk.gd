class_name KertasPetunjuk
extends Interactable
# Kertas petunjuk di pojok/lantai. Diambil dengan E, disimpan ke Catatan (bukan slot Inventory).

var data: Level3Generator.Kertas
var ui: Level3UI
var diambil := false
var _bentuk: CollisionShape2D

static func buat(k: Level3Generator.Kertas, panel_ui: Level3UI) -> KertasPetunjuk:
	var n := KertasPetunjuk.new()
	n.data = k
	n.ui = panel_ui
	n.position = k.posisi
	n.name = "Kertas_%d" % k.posisi_angka
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("kertas_petunjuk")

func _bangun() -> void:
	collision_layer = 2
	collision_mask = 0
	interact_name = "Ambil kertas"
	# placeholder: kotak putih kecil berbingkai abu-abu
	var tepi := Polygon2D.new()
	tepi.color = Color(0.5, 0.5, 0.5)
	tepi.polygon = PackedVector2Array([Vector2(-5, -4), Vector2(5, -4), Vector2(5, 4), Vector2(-5, 4)])
	add_child(tepi)
	var isi := Polygon2D.new()
	isi.color = Color.WHITE
	isi.polygon = PackedVector2Array([Vector2(-4, -3), Vector2(4, -3), Vector2(4, 3), Vector2(-4, 3)])
	add_child(isi)
	_bentuk = CollisionShape2D.new()
	var lingkar := CircleShape2D.new()
	lingkar.radius = 14.0
	_bentuk.shape = lingkar
	add_child(_bentuk)

func interact() -> void:
	if diambil or ui == null:
		return
	diambil = true
	is_interactable = false
	ui.tambah_catatan(data)
	hide()
	_bentuk.set_deferred("disabled", true)   # keluar dari daftar interaksi pemain (area_exited)
