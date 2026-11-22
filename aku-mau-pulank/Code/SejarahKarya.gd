class_name SejarahKarya
extends Interactable
# Karya pameran sejarah (miniatur/lukisan hologram). Dibuat lewat kode oleh level4_manager.gd.
# MINIATUR: berdiri di lantai, ada StaticBody2D. LUKISAN: menempel di dinding, tanpa StaticBody2D.

const WARNA_ALAS := Color(0.45, 0.4, 0.35)
const WARNA_MINIATUR := Color(0.85, 0.7, 0.4)
const WARNA_BINGKAI := Color(0.1, 0.45, 0.55)
const WARNA_KANVAS := Color(0.75, 0.95, 1.0, 0.9)

var data: SejarahKaryaData
var ui: SejarahUI
var _penanda: Label

static func buat(d: SejarahKaryaData, pos: Vector2, panel_ui: SejarahUI) -> SejarahKarya:
	var n := SejarahKarya.new()
	n.data = d
	n.position = pos
	n.ui = panel_ui
	n.name = "Karya_%s" % d.id
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("sejarah_karya")

func _bangun() -> void:
	collision_layer = 2   # layer interaksi (dibaca Area2D "interacting" milik pemain, mask 2)
	collision_mask = 0
	var bentuk := CollisionShape2D.new()
	if data.tipe == SejarahKaryaData.Tipe.MINIATUR:
		interact_name = "Periksa Miniatur"
		_bangun_miniatur(bentuk)
	else:
		interact_name = "Periksa Lukisan"
		_bangun_lukisan(bentuk)
	add_child(bentuk)
	_penanda = Label.new()
	_penanda.text = "v"
	_penanda.add_theme_font_size_override("font_size", 7)
	_penanda.add_theme_color_override("font_color", Color(0.1, 0.65, 0.2))
	_penanda.position = Vector2(-2, -38 if data.tipe == SejarahKaryaData.Tipe.MINIATUR else -24)
	_penanda.visible = false
	add_child(_penanda)

func _bangun_miniatur(bentuk: CollisionShape2D) -> void:
	if data.texture != null:
		_tambah_sprite(28.0)
	else:
		add_child(_kotak(Rect2(-9, -5, 18, 5), WARNA_ALAS))          # alas
		add_child(_kotak(Rect2(-6, -17, 12, 12), WARNA_MINIATUR))    # bangunan
		var atap := Polygon2D.new()                                   # atap segitiga
		atap.color = WARNA_ALAS
		atap.polygon = PackedVector2Array([Vector2(-8, -17), Vector2(0, -26), Vector2(8, -17)])
		add_child(atap)
	var badan := StaticBody2D.new()   # miniatur menghalangi pemain
	badan.name = "Badan"
	var kb := CollisionShape2D.new()
	var rb := RectangleShape2D.new()
	rb.size = Vector2(16, 6)
	kb.shape = rb
	kb.position = Vector2(0, -3)
	badan.add_child(kb)
	add_child(badan)
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
	s.position = Vector2(0, -tinggi_target * 0.5 if data.tipe == SejarahKaryaData.Tipe.MINIATUR else 0.0)
	add_child(s)

func interact() -> void:
	if ui == null or data == null:
		return
	ui.buka_label(self)
	await ui.closed

func tandai_dibaca() -> void:
	_penanda.visible = true
