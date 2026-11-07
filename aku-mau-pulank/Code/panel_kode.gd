class_name PanelKode
extends Interactable
# Panel kode di samping pintu keluar + logika pintu. Dibuat lewat kode oleh level3_manager.gd.

signal level_selesai

var kode: Array[int] = []   # kode jawaban (dari generator)
var pintu: Node2D           # node pintu (punya anak "Pintu/CollisionShape2D")
var ui: Level3UI
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
	n.add_child(_tulisan("PINTU - menuju level berikutnya", Vector2(-32, -44), 64))
	return n

static func buat(pos: Vector2, kode_benar: Array[int], pintu_node: Node2D, panel_ui: Level3UI) -> PanelKode:
	var n := PanelKode.new()
	n.name = "PanelKode"
	n.position = pos
	n.kode = kode_benar
	n.pintu = pintu_node
	n.ui = panel_ui
	n._bangun()
	return n

func _ready() -> void:
	add_to_group("panel_kode")

func _bangun() -> void:
	collision_layer = 2
	collision_mask = 0
	interact_name = "Masukkan kode"
	var layar := Polygon2D.new()
	layar.color = Color(0.1, 0.15, 0.4)
	layar.polygon = PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(8, 8), Vector2(-8, 8)])
	add_child(layar)
	var lampu := Polygon2D.new()
	lampu.color = Color(0.3, 0.9, 0.5)
	lampu.polygon = PackedVector2Array([Vector2(-5, -9), Vector2(5, -9), Vector2(5, -4), Vector2(-5, -4)])
	add_child(lampu)
	add_child(_tulisan("KODE", Vector2(-14, -26), 28))
	var badan := StaticBody2D.new()   # panel tidak bisa ditembus
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

static func _tulisan(teks: String, pos: Vector2, lebar: float) -> Label:
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
	if terbuka or ui == null:
		return
	ui.buka_kode(self)
	await ui.closed

# Dipanggil UI. true = kode benar (pintu langsung dibuka).
func coba_kode(teks: String) -> bool:
	if terbuka:
		return true
	if teks.length() != kode.size():
		return false
	for i in kode.size():
		if teks[i] != str(kode[i]):
			return false
	_buka_pintu()
	return true

func _buka_pintu() -> void:
	terbuka = true
	is_interactable = false
	if pintu != null:
		pintu.get_node("Pintu/CollisionShape2D").set_deferred("disabled", true)
		pintu.hide()
	_bentuk.set_deferred("disabled", true)   # keluar dari daftar interaksi pemain
	InventoryUI.show_message("Pintu terbuka!")
	level_selesai.emit()
