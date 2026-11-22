class_name SejarahKertasKategori
extends Interactable
# Kertas catatan kategori di sebelah mesin. Dibaca dengan E ("Baca catatan").

var ui: SejarahUI

static func buat(pos: Vector2, panel_ui: SejarahUI) -> SejarahKertasKategori:
	var n := SejarahKertasKategori.new()
	n.position = pos
	n.ui = panel_ui
	n.name = "KertasKategori"
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("sejarah_kertas_kategori")

func _bangun() -> void:
	collision_layer = 2
	collision_mask = 0
	interact_name = "Baca catatan"
	var tepi := Polygon2D.new()   # placeholder: kertas putih berbingkai abu-abu
	tepi.color = Color(0.5, 0.5, 0.5)
	tepi.polygon = PackedVector2Array([Vector2(-7, -14), Vector2(7, -14), Vector2(7, 2), Vector2(-7, 2)])
	add_child(tepi)
	var isi := Polygon2D.new()
	isi.color = Color.WHITE
	isi.polygon = PackedVector2Array([Vector2(-6, -13), Vector2(6, -13), Vector2(6, 1), Vector2(-6, 1)])
	add_child(isi)
	add_child(SejarahMesin.tulisan("KATEGORI", Vector2(-18, -26), 36))
	var badan := StaticBody2D.new()
	var kb := CollisionShape2D.new()
	var rb := RectangleShape2D.new()
	rb.size = Vector2(14, 6)
	kb.shape = rb
	kb.position = Vector2(0, -1)
	badan.add_child(kb)
	add_child(badan)
	var bentuk := CollisionShape2D.new()
	var lingkar := CircleShape2D.new()
	lingkar.radius = 20.0
	bentuk.shape = lingkar
	bentuk.position = Vector2(0, -4)
	add_child(bentuk)

func interact() -> void:
	if ui == null:
		return
	ui.buka_kategori()
	await ui.closed
