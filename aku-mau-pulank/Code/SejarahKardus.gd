class_name SejarahKardus
extends Interactable
# Kardus berisi potongan kertas. Interaksi pertama: semua potongan masuk ke tumpukan pemain
# (bukan Inventory), lalu kardus menjadi "Kardus kosong".

var logika: SejarahMesinLogika
var _badan_visual: Polygon2D

static func buat(pos: Vector2, logika_mesin: SejarahMesinLogika) -> SejarahKardus:
	var n := SejarahKardus.new()
	n.position = pos
	n.logika = logika_mesin
	n.name = "Kardus"
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("sejarah_kardus")

func _bangun() -> void:
	collision_layer = 2
	collision_mask = 0
	interact_name = "Ambil potongan kertas"
	_badan_visual = Polygon2D.new()   # placeholder: kotak cokelat
	_badan_visual.color = Color(0.65, 0.48, 0.28)
	_badan_visual.polygon = PackedVector2Array([Vector2(-9, -12), Vector2(9, -12), Vector2(9, 0), Vector2(-9, 0)])
	add_child(_badan_visual)
	var lakban := Polygon2D.new()
	lakban.color = Color(0.85, 0.72, 0.45)
	lakban.polygon = PackedVector2Array([Vector2(-2, -12), Vector2(2, -12), Vector2(2, 0), Vector2(-2, 0)])
	add_child(lakban)
	var badan := StaticBody2D.new()
	var kb := CollisionShape2D.new()
	var rb := RectangleShape2D.new()
	rb.size = Vector2(16, 6)
	kb.shape = rb
	kb.position = Vector2(0, -3)
	badan.add_child(kb)
	add_child(badan)
	var bentuk := CollisionShape2D.new()
	var lingkar := CircleShape2D.new()
	lingkar.radius = 22.0
	bentuk.shape = lingkar
	bentuk.position = Vector2(0, -6)
	add_child(bentuk)

func interact() -> void:
	if logika == null:
		return
	if logika.ambil_dari_kardus():
		InventoryUI.show_message("Kamu mengambil %d potongan kertas" % logika.jumlah_total())
		interact_name = "Kardus kosong"
		_badan_visual.color = Color(0.45, 0.4, 0.35)
	else:
		InventoryUI.show_message("Kardus ini sudah kosong")
