class_name KaryaPameran
extends Interactable
# Karya pameran (patung/lukisan). Dibuat lewat kode oleh level3_manager.gd.
# PATUNG: berdiri di lantai, ada StaticBody2D. LUKISAN: menempel di dinding, tanpa StaticBody2D.

const WARNA_PATUNG := Color(0.3, 0.75, 0.95, 0.9)
const WARNA_ALAS := Color(0.45, 0.45, 0.5)
const WARNA_BINGKAI := Color(0.45, 0.28, 0.12)
const WARNA_KANVAS := Color(0.95, 0.9, 0.75)

var data: ExhibitData
var bbcode := ""                       # deskripsi dengan kata berwarna (dari generator)
var kertas: Level3Generator.Kertas     # kertas terselip di karya ini (boleh null)
var kertas_diambil := false
var ui: Level3UI
var _penanda: Label

static func buat(d: ExhibitData, pos: Vector2, bb: String, panel_ui: Level3UI) -> KaryaPameran:
	var n := KaryaPameran.new()
	n.data = d
	n.position = pos
	n.bbcode = bb
	n.ui = panel_ui
	n.name = "Karya_%s" % d.id
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("karya_pameran")

func _bangun() -> void:
	collision_layer = 2   # layer interaksi (dibaca Area2D "interacting" milik pemain, mask 2)
	collision_mask = 0
	var bentuk := CollisionShape2D.new()
	if data.tipe == ExhibitData.Tipe.PATUNG:
		interact_name = "Periksa Patung"
		_bangun_patung(bentuk)
	else:
		interact_name = "Periksa Lukisan"
		_bangun_lukisan(bentuk)
	add_child(bentuk)
	_penanda = Label.new()
	_penanda.text = "v"
	_penanda.add_theme_font_size_override("font_size", 7)
	_penanda.add_theme_color_override("font_color", Color(0.1, 0.65, 0.2))
	_penanda.position = Vector2(-2, -42 if data.tipe == ExhibitData.Tipe.PATUNG else -24)
	_penanda.visible = false
	add_child(_penanda)

func _bangun_patung(bentuk: CollisionShape2D) -> void:
	if data.texture != null:
		_tambah_sprite(28.0)
	else:
		add_child(_kotak(Rect2(-8, -5, 16, 5), WARNA_ALAS))        # alas
		add_child(_kotak(Rect2(-5, -21, 10, 16), WARNA_PATUNG))    # badan hologram
		add_child(_kotak(Rect2(-3.5, -27, 7, 6), WARNA_PATUNG))    # kepala
	# badan fisik yang menghalangi pemain
	var badan := StaticBody2D.new()
	badan.name = "Badan"
	var kb := CollisionShape2D.new()
	var rb := RectangleShape2D.new()
	rb.size = Vector2(14, 6)
	kb.shape = rb
	kb.position = Vector2(0, -3)
	badan.add_child(kb)
	add_child(badan)
	# jangkauan interaksi
	var lingkar := CircleShape2D.new()
	lingkar.radius = 22.0
	bentuk.shape = lingkar
	bentuk.position = Vector2(0, -8)

func _bangun_lukisan(bentuk: CollisionShape2D) -> void:
	z_index = 1   # tampil di atas tile dinding; tanpa StaticBody2D karena menempel di dinding
	if data.texture != null:
		_tambah_sprite(16.0)
	else:
		add_child(_kotak(Rect2(-14, -8, 28, 16), WARNA_BINGKAI))
		add_child(_kotak(Rect2(-12, -6, 24, 12), WARNA_KANVAS))
	# jangkauan memanjang ke bawah supaya pemain di lantai depan dinding bisa menekan E
	var kotak := RectangleShape2D.new()
	kotak.size = Vector2(40, 52)
	bentuk.shape = kotak
	bentuk.position = Vector2(0, 14)

func _kotak(r: Rect2, warna: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = warna
	p.polygon = PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	return p

func _tambah_sprite(tinggi_target: float) -> void:
	var s := Sprite2D.new()
	s.texture = data.texture
	var skala := tinggi_target / maxf(float(data.texture.get_height()), 1.0)
	s.scale = Vector2(skala, skala)
	s.position = Vector2(0, -tinggi_target * 0.5 if data.tipe == ExhibitData.Tipe.PATUNG else 0.0)
	add_child(s)

func interact() -> void:
	if ui == null or data == null:
		return
	ui.buka_label(self)
	await ui.closed

func tandai_dibaca() -> void:
	_penanda.visible = true

# Dipanggil tombol "Ambil kertas terselip" di panel label.
func ambil_kertas() -> void:
	if kertas == null or kertas_diambil:
		return
	kertas_diambil = true
	ui.tambah_catatan(kertas)
