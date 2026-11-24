class_name PintuKeluar
extends RefCounted
# Helper bersama untuk pintu terkunci dan hitbox/portal keluar menuju level berikutnya.

static func buat_pintu_terkunci(pos: Vector2, label_teks: String) -> Node2D:
	var n := Node2D.new()
	n.name = "PintuKeluar"
	n.position = pos

	var badan := StaticBody2D.new()
	badan.name = "Pintu"
	n.add_child(badan)

	# Kusen luar
	var kusen := Polygon2D.new()
	kusen.color = Color(0.24, 0.16, 0.10, 1.0)
	kusen.polygon = PackedVector2Array([Vector2(-13, -15), Vector2(13, -15), Vector2(13, 11), Vector2(-13, 11)])
	badan.add_child(kusen)

	# Daun pintu kayu
	var daun := Polygon2D.new()
	daun.color = Color(0.42, 0.27, 0.15, 1.0)
	daun.polygon = PackedVector2Array([Vector2(-10, -12), Vector2(10, -12), Vector2(10, 9), Vector2(-10, 9)])
	badan.add_child(daun)

	# Gagang/kunci emas
	var kunci := Polygon2D.new()
	kunci.color = Color(0.88, 0.70, 0.30, 1.0)
	kunci.polygon = PackedVector2Array([Vector2(4, -3), Vector2(7, -3), Vector2(7, 1), Vector2(4, 1)])
	badan.add_child(kunci)

	var bentuk := CollisionShape2D.new()
	bentuk.name = "CollisionShape2D"
	var persegi := RectangleShape2D.new()
	persegi.size = Vector2(24, 24)
	bentuk.shape = persegi
	badan.add_child(bentuk)

	n.add_child(buat_label_dunia(label_teks, Vector2(-34, -34), 68))
	return n

static func buat_pemicu_keluar(pos: Vector2, label_teks: String, on_body_entered: Callable) -> Area2D:
	var pemicu := Area2D.new()
	pemicu.name = "PemicuKeluar"
	pemicu.collision_layer = 0
	pemicu.collision_mask = 1   # layer pemain
	pemicu.position = pos

	# Ambang pintu terbuka bercahaya lembut
	var cahaya := Polygon2D.new()
	cahaya.color = Color(0.28, 0.78, 0.45, 0.38)
	cahaya.polygon = PackedVector2Array([Vector2(-13, -13), Vector2(13, -13), Vector2(13, 13), Vector2(-13, 13)])
	cahaya.z_index = -1
	pemicu.add_child(cahaya)

	var inti := Polygon2D.new()
	inti.color = Color(0.95, 0.84, 0.48, 0.55)
	inti.polygon = PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	inti.z_index = -1
	pemicu.add_child(inti)

	pemicu.add_child(buat_label_dunia(label_teks, Vector2(-36, -32), 72, Color(0.98, 0.92, 0.65, 1.0)))

	var bentuk := CollisionShape2D.new()
	var kotak := RectangleShape2D.new()
	kotak.size = Vector2(28, 28)
	bentuk.shape = kotak
	pemicu.add_child(bentuk)

	pemicu.body_entered.connect(on_body_entered)
	return pemicu

static func buat_label_dunia(teks: String, pos: Vector2, lebar: float, warna: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = teks
	l.position = pos
	l.size = Vector2(lebar, 10)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 5
	l.add_theme_font_size_override("font_size", 7)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l
