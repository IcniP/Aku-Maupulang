class_name KertasClue
extends Interactable
# Kertas CLUE: kertas informasi yang tersebar di lantai atau menempel di dinding atas/kiri/kanan.
# Berbeda dengan KertasPetunjuk (kertas kode): kertas ini TIDAK diambil dan tidak hilang,
# jadi pemain bisa membacanya lagi kapan saja. Dibuat lewat kode oleh level3_manager.gd.
# (Clue yang terselip di lukisan ditangani KaryaPameran + Level3UI.)

const WARNA_TEPI := Color(0.25, 0.45, 0.65)
const WARNA_KERTAS := Color(0.78, 0.92, 1.0)   # biru muda, beda dari kertas kode yang putih

var data: Level3Generator.ClueKertas
var ui: Level3UI
var _tampilan: Node2D

static func buat(c: Level3Generator.ClueKertas, panel_ui: Level3UI) -> KertasClue:
	var n := KertasClue.new()
	n.data = c
	n.ui = panel_ui
	n.position = c.posisi
	n.name = "Clue_%d" % c.indeks_teks
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("kertas_clue")
	var tween := create_tween().set_loops()   # kilau biru muda pelan supaya mudah ditemukan
	tween.tween_property(_tampilan, "modulate", Color(0.7, 0.85, 1.0), 0.9)
	tween.tween_property(_tampilan, "modulate", Color.WHITE, 0.9)

func _bangun() -> void:
	collision_layer = 2   # layer interaksi (dibaca Area2D "interacting" milik pemain, mask 2)
	collision_mask = 0
	interact_name = "Baca kertas"
	_tampilan = Node2D.new()
	add_child(_tampilan)
	var bentuk := CollisionShape2D.new()
	if data.tipe == Level3Generator.TipeClue.DINDING_ATAS:
		# menempel di dinding atas: tampil di atas tile dinding; jangkauan memanjang ke bawah seperti lukisan
		z_index = 1
		_kotak(Rect2(-6, -9, 12, 16), WARNA_TEPI)
		_kotak(Rect2(-5, -8, 10, 14), WARNA_KERTAS)
		_garis_teks(-5, -4, 5, 3)
		var kotak := RectangleShape2D.new()
		kotak.size = Vector2(36, 48)
		bentuk.shape = kotak
		bentuk.position = Vector2(0, 14)
	elif data.tipe == Level3Generator.TipeClue.DINDING_SAMPING:
		# menempel di dinding kiri atau kanan
		z_index = 1
		_kotak(Rect2(-5, -8, 10, 16), WARNA_TEPI)
		_kotak(Rect2(-4, -7, 8, 14), WARNA_KERTAS)
		_garis_teks(-4, -3, 4, 3)
		var lingkar := CircleShape2D.new()
		lingkar.radius = 22.0
		bentuk.shape = lingkar
	else:
		# tergeletak di lantai
		_kotak(Rect2(-7, -5, 14, 10), WARNA_TEPI)
		_kotak(Rect2(-6, -4, 12, 8), WARNA_KERTAS)
		_garis_teks(-5, -2, 5, 3)
		var lingkar := CircleShape2D.new()
		lingkar.radius = 18.0
		bentuk.shape = lingkar
	add_child(bentuk)

func _kotak(r: Rect2, warna: Color) -> void:
	var p := Polygon2D.new()
	p.color = warna
	p.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	_tampilan.add_child(p)

# Garis-garis kecil sebagai "tulisan" pada kertas.
func _garis_teks(x0: float, y0: float, x1: float, langkah: int) -> void:
	for i in 2:
		_kotak(Rect2(x0 + 1, y0 + i * langkah, x1 - x0 - 2, 1), WARNA_TEPI)

func interact() -> void:
	if ui == null or data == null:
		return
	ui.buka_clue(data.indeks_teks, false)
	await ui.closed
