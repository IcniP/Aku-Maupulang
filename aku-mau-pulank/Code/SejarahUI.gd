class_name SejarahUI
extends CanvasLayer
# UI Level 4 lewat kode (pola Level3UI/StoryUI): panel LABEL karya, panel MESIN (BENAR/SALAH/TIDAK ADA),
# panel TUMPUKAN potongan (tombol N, read-only), dan panel CATATAN KATEGORI.

signal closed

const LEBAR_PANEL := 580
const AKSI_TUMPUKAN := "tumpukan_potongan"   # tombol N, didaftarkan lewat kode (bukan project.godot)

var logika: SejarahMesinLogika
var mesin_node: SejarahMesin
var total_karya := 0
var jeda_periksa := 1.2   # detik "Memeriksa..." (timer tetap jalan saat game di-pause)

var _backdrop: ColorRect
var _aktif: Control
var _panel_label: PanelContainer
var _teks_label: RichTextLabel
var _panel_mesin: PanelContainer
var _judul_mesin: Label
var _hitung_mesin: Label
var _daftar: ItemList
var _teks_pilihan: RichTextLabel
var _tombol_kategori: Array[Button] = []
var _status_mesin: Label
var _panel_tumpukan: PanelContainer
var _teks_tumpukan: RichTextLabel
var _panel_kategori: PanelContainer
var _dibaca := {}
var _memeriksa := false

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS   # tetap jalan saat game di-pause
	add_to_group("sejarah_ui")
	_daftarkan_aksi()
	_backdrop = UITheme.make_backdrop()
	add_child(_backdrop)
	_bangun_label()
	_bangun_mesin()
	_bangun_tumpukan()
	_bangun_kategori()

# Tombol N didaftarkan lewat kode supaya project.godot tidak berubah.
func _daftarkan_aksi() -> void:
	if not InputMap.has_action(AKSI_TUMPUKAN):
		InputMap.add_action(AKSI_TUMPUKAN)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_N
		InputMap.action_add_event(AKSI_TUMPUKAN, ev)

# ---------------------------------------------------------------- pembangun panel

func _panel_putih() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	UITheme.style_parchment_panel(p, 24, 20)
	add_child(p)
	return p

func _teks_hitam(tinggi_min: float = 0.0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(LEBAR_PANEL, tinggi_min)
	r.add_theme_color_override("default_color", UITheme.TEXT_DARK)
	return r

func _label_hitam(teks: String, ukuran: int = 15) -> Label:
	var l := Label.new()
	l.text = teks
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = LEBAR_PANEL
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", UITheme.TEXT_DARK)
	return l

func _tombol(teks: String, aksi: Callable, variant: String = "secondary") -> Button:
	var b := Button.new()
	b.text = teks
	UITheme.style_button(b, variant)
	b.pressed.connect(aksi)
	return b

func _bangun_label() -> void:
	_panel_label = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	_panel_label.add_child(kolom)
	var kartu := PanelContainer.new()
	UITheme.style_inner_box(kartu, 14, false)
	kolom.add_child(kartu)
	_teks_label = _teks_hitam()
	kartu.add_child(_teks_label)
	kolom.add_child(_tombol("Tutup", tutup, "secondary"))

func _bangun_mesin() -> void:
	_panel_mesin = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	_panel_mesin.add_child(kolom)

	var header := HBoxContainer.new()
	kolom.add_child(header)
	_judul_mesin = UITheme.make_title("Mesin Klasifikasi Sejarah", 21, false)
	_judul_mesin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_judul_mesin)
	_hitung_mesin = UITheme.make_body("", 14, true, false)
	_hitung_mesin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_hitung_mesin)
	kolom.add_child(UITheme.make_divider(false))

	_daftar = ItemList.new()
	_daftar.custom_minimum_size = Vector2(LEBAR_PANEL, 165)
	_daftar.max_text_lines = 2
	_daftar.focus_mode = Control.FOCUS_NONE
	_daftar.item_selected.connect(_saat_dipilih)
	kolom.add_child(_daftar)

	var pilihan_card := PanelContainer.new()
	UITheme.style_inner_box(pilihan_card, 12, false)
	kolom.add_child(pilihan_card)
	_teks_pilihan = _teks_hitam(54)
	pilihan_card.add_child(_teks_pilihan)

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kolom.add_child(baris)
	var varian := ["success", "danger", "primary"]
	for k in 3:
		var b := _tombol(SejarahData.nama_kategori(k), _pilih_kategori.bind(k), varian[k])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		baris.add_child(b)
		_tombol_kategori.append(b)

	_status_mesin = _label_hitam("")
	_status_mesin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_mesin.add_theme_color_override("font_color", UITheme.ACCENT_PRIMARY)
	kolom.add_child(_status_mesin)
	kolom.add_child(_tombol("Tutup", tutup, "secondary"))

func _bangun_tumpukan() -> void:
	_panel_tumpukan = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	_panel_tumpukan.add_child(kolom)

	var header := HBoxContainer.new()
	kolom.add_child(header)
	var judul := UITheme.make_title("Tumpukan Potongan", 22, false)
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(judul)
	var hint := UITheme.make_body("N / Esc untuk menutup", 13, true, false)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(hint)
	kolom.add_child(UITheme.make_divider(false))

	var kartu := PanelContainer.new()
	UITheme.style_inner_box(kartu, 14, false)
	kolom.add_child(kartu)
	_teks_tumpukan = _teks_hitam()
	kartu.add_child(_teks_tumpukan)
	kolom.add_child(_tombol("Tutup", tutup, "secondary"))

func _bangun_kategori() -> void:
	_panel_kategori = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	_panel_kategori.add_child(kolom)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.add_child(UITheme.make_title("Catatan Kategori", 22, false))
	header.add_child(UITheme.make_divider(false))
	kolom.add_child(header)
	var teks := _teks_hitam()
	teks.add_theme_stylebox_override("normal", UITheme.make_box(UITheme.CARD_INNER, UITheme.BORDER_SOFT, 1, 10, 14, 14))
	teks.text = SejarahData.TEKS_KATEGORI
	kolom.add_child(teks)
	kolom.add_child(_tombol("Tutup", tutup, "secondary"))

# ---------------------------------------------------------------- API untuk objek

func buka_label(karya: SejarahKarya) -> void:
	var d := karya.data
	_dibaca[d.id] = true
	karya.tandai_dibaca()
	_teks_label.text = "[font_size=22][b]%s[/b][/font_size]\nDaerah/era: %s\n\n%s" % [
		_esc(d.judul), _esc(d.era), d.teks_label]
	_tampilkan(_panel_label)

func buka_mesin() -> void:
	_status_mesin.text = ""
	_segarkan_mesin()
	_tampilkan(_panel_mesin)

func buka_tumpukan() -> void:
	_segarkan_tumpukan()
	_tampilkan(_panel_tumpukan)

func buka_kategori() -> void:
	_tampilkan(_panel_kategori)

func tutup() -> void:
	if _aktif == null:
		return
	_backdrop.visible = false
	_aktif.visible = false
	_aktif = null
	get_tree().paused = false
	closed.emit()

func sedang_terbuka() -> bool:
	return _aktif != null

func jumlah_dibaca() -> int:
	return _dibaca.size()

# ---------------------------------------------------------------- internal

func _tampilkan(panel: Control) -> void:
	if _aktif != null:
		_aktif.visible = false
	_aktif = panel
	_backdrop.visible = true
	panel.visible = true
	get_tree().paused = true

func _segarkan_mesin() -> void:
	_daftar.clear()
	_teks_pilihan.text = ""
	if logika == null:
		return
	for idx in logika.tumpukan:
		var n := _daftar.add_item("%d. %s" % [idx + 1, logika.potongan[idx].teks])
		_daftar.set_item_metadata(n, idx)
	_hitung_mesin.text = "%d/%d dimasukkan" % [logika.jumlah_dimasukkan(), logika.jumlah_total()]
	if _daftar.item_count > 0:
		_daftar.select(0)
		_saat_dipilih(0)
	else:
		_set_tombol(false)

func _saat_dipilih(n: int) -> void:
	var idx: int = _daftar.get_item_metadata(n)
	_teks_pilihan.text = "[b]Potongan %d:[/b] %s" % [idx + 1, _esc(logika.potongan[idx].teks)]
	_set_tombol(not _memeriksa)

func _set_tombol(aktif: bool) -> void:
	for b in _tombol_kategori:
		b.disabled = not aktif

# Masukkan potongan terpilih ke mesin sebagai kategori k (tidak bisa ditarik kembali).
func _pilih_kategori(k: int) -> void:
	if _memeriksa or logika == null:
		return
	var terpilih := _daftar.get_selected_items()
	if terpilih.is_empty():
		return
	var idx: int = _daftar.get_item_metadata(terpilih[0])
	if not logika.masukkan(idx, k):
		return
	_segarkan_mesin()
	if logika.semua_masuk():
		_periksa()

func _periksa() -> void:
	_memeriksa = true
	_set_tombol(false)
	_status_mesin.text = "Memeriksa..."
	await get_tree().create_timer(jeda_periksa, true).timeout   # process_always = true
	_memeriksa = false
	_status_mesin.text = ""
	if mesin_node != null:
		mesin_node.selesai_memasukkan()
	tutup()

func _segarkan_tumpukan() -> void:
	var s := ""
	if logika == null or not logika.kardus_diambil:
		s = "Belum ada potongan kertas. Ambil dari kardus lebih dulu."
	else:
		s = "Dimasukkan ke mesin: %d/%d.   Di tangan: %d potongan.\n\n" % [
			logika.jumlah_dimasukkan(), logika.jumlah_total(), logika.jumlah_tumpukan()]
		if logika.tumpukan.is_empty():
			s += "Tumpukan kosong."
		for idx in logika.tumpukan:
			s += "[b]%d.[/b] %s\n" % [idx + 1, _esc(logika.potongan[idx].teks)]
	s += "\n\nKarya diperiksa: %d/%d" % [_dibaca.size(), total_karya]
	_teks_tumpukan.text = s

func _esc(teks: String) -> String:
	return teks.replace("[", "[lb]")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _aktif != null:
		if not _memeriksa:   # jangan tutup saat "Memeriksa..."
			tutup()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(AKSI_TUMPUKAN):
		if _aktif == _panel_tumpukan:
			tutup()
		elif _aktif == null and not get_tree().paused:   # jangan buka saat panel lain terbuka
			buka_tumpukan()
